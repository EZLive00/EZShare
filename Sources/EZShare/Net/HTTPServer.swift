import Foundation
import Network

/// 轻量 HTTP/1.1 服务端：基于 Network.framework，无第三方依赖。
final class HTTPServer {
    enum State {
        case idle
        case starting
        case running(UInt16)
        case failed(String)
    }

    private let queue = DispatchQueue(label: "com.ezshare.http", qos: .userInitiated)
    private let router: Router
    private var listener: NWListener?
    private var connections: [UUID: HTTPConnectionHandler] = [:]
    private var stopping = true
    private var retryBudget = 0

    var onState: ((State) -> Void)?
    var onLog: ((AccessLog) -> Void)?
    var onTraffic: ((Int64) -> Void)?

    init(router: Router) {
        self.router = router
    }

    func start(preferredPort: UInt16) {
        queue.async {
            self.stopping = false
            self.retryBudget = 12
            self.listen(port: preferredPort)
        }
    }

    func stop() {
        queue.async {
            self.stopping = true
            self.listener?.stateUpdateHandler = nil
            self.listener?.newConnectionHandler = nil
            self.listener?.cancel()
            self.listener = nil
            let handlers = Array(self.connections.values)
            self.connections.removeAll()
            for handler in handlers { handler.close() }
            self.emitState(.idle)
        }
    }

    private func listen(port: UInt16) {
        guard !stopping else { return }
        guard port > 0, let nwPort = NWEndpoint.Port(rawValue: port) else {
            emitState(.failed("端口无效"))
            return
        }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = false

        do {
            let listener = try NWListener(using: parameters, on: nwPort)
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    self.emitState(.running(port))
                case .failed(let error):
                    self.listener?.stateUpdateHandler = nil
                    self.listener?.cancel()
                    self.listener = nil
                    self.retry(port: port, error: error)
                default:
                    break
                }
            }
            self.listener = listener
            emitState(.starting)
            listener.start(queue: queue)
        } catch {
            retry(port: port, error: error)
        }
    }

    private func retry(port: UInt16, error: Error) {
        guard !stopping, retryBudget > 0, port < 65_535 else {
            emitState(.failed(error.localizedDescription))
            return
        }
        retryBudget -= 1
        listen(port: port + 1)
    }

    private func accept(_ connection: NWConnection) {
        let handler = HTTPConnectionHandler(connection: connection, queue: queue, router: router, server: self)
        connections[handler.id] = handler
        handler.start()
    }

    func finish(connectionID: UUID) {
        connections[connectionID] = nil
    }

    func record(_ log: AccessLog) {
        let callback = onLog
        DispatchQueue.main.async { callback?(log) }
    }

    func addTraffic(_ delta: Int64) {
        let callback = onTraffic
        DispatchQueue.main.async { callback?(delta) }
    }

    private func emitState(_ state: State) {
        let callback = onState
        DispatchQueue.main.async { callback?(state) }
    }
}

// MARK: - 单连接处理

final class HTTPConnectionHandler {
    private enum Mode {
        case readingHead
        case bufferingBody
        case streamingUpload(UploadSink)
        case done
    }

    let id = UUID()
    private let connection: NWConnection
    private let queue: DispatchQueue
    private let router: Router
    private unowned let server: HTTPServer

    private var buffer = Data()
    private var body = Data()
    private var mode: Mode = .readingHead
    private var request: HTTPRequest?
    private var expectedBody = 0
    private var chunkedDecoder: ChunkedDecoder?
    private var closed = false
    private var peer = "-"

    private static let maxHeadBytes = 64 * 1024
    private static let maxBufferedBody = 8 * 1024 * 1024

    init(connection: NWConnection, queue: DispatchQueue, router: Router, server: HTTPServer) {
        self.connection = connection
        self.queue = queue
        self.router = router
        self.server = server
        if case let .hostPort(host, port) = connection.endpoint {
            self.peer = "\(host):\(port.rawValue)"
        }
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.close()
            default:
                break
            }
        }
        connection.start(queue: queue)
        receive()
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 256 * 1024) { [weak self] data, _, isComplete, error in
            guard let self, !self.closed else { return }
            if let data, !data.isEmpty { self.consume(data) }
            if self.closed { return }
            if error != nil || isComplete {
                self.close()
                return
            }
            self.receive()
        }
    }

    private func consume(_ data: Data) {
        switch mode {
        case .done:
            return

        case .readingHead:
            buffer.append(data)
            guard let headRange = buffer.range(of: Data("\r\n\r\n".utf8)) else {
                if buffer.count > Self.maxHeadBytes {
                    buffer.removeAll(keepingCapacity: false)
                    respond(.text("请求头过大", status: 431))
                }
                return
            }
            let headData = buffer.subdata(in: buffer.startIndex..<headRange.lowerBound)
            let rest = buffer.subdata(in: headRange.upperBound..<buffer.endIndex)
            buffer.removeAll(keepingCapacity: false)

            guard let text = String(data: headData, encoding: .utf8),
                  let (parsed, contentLength) = HTTPParser.parseHead(text) else {
                respond(.text("请求格式错误", status: 400))
                return
            }
            request = parsed

            if parsed.method == "PUT" && parsed.path == "/api/upload" {
                beginUpload(parsed, contentLength: contentLength, initialData: rest)
                return
            }

            expectedBody = contentLength
            if expectedBody > Self.maxBufferedBody {
                respond(.text("请求体过大", status: 413))
                return
            }
            mode = .bufferingBody
            if !rest.isEmpty { consume(rest) }
            if case .bufferingBody = mode, body.count >= expectedBody { dispatch() }

        case .bufferingBody:
            body.append(data)
            if body.count >= expectedBody { dispatch() }

        case .streamingUpload(let sink):
            feedUpload(data, sink: sink)
        }
    }

    private func dispatch() {
        guard var parsed = request else { return }
        parsed.body = body
        let response = router.handle(parsed)
        respond(response)
    }

    // MARK: - 上传

    private func beginUpload(_ parsed: HTTPRequest, contentLength: Int, initialData: Data) {
        switch router.uploadPlan(for: parsed) {
        case .reject(let response):
            respond(response)
        case .stream(let fileURL, _):
            guard let sink = UploadSink(url: fileURL) else {
                respond(.json(["ok": false, "error": "无法创建文件"], status: 500))
                return
            }
            let isChunked = (parsed.header("transfer-encoding") ?? "").lowercased().contains("chunked")
            mode = .streamingUpload(sink)
            if isChunked {
                chunkedDecoder = ChunkedDecoder()
            } else {
                expectedBody = contentLength
                if contentLength <= 0 {
                    finishUpload(sink: sink)
                    return
                }
            }
            if !initialData.isEmpty { feedUpload(initialData, sink: sink) }
        }
    }

    private func feedUpload(_ data: Data, sink: UploadSink) {
        if let decoder = chunkedDecoder {
            decoder.feed(data) { chunk in sink.write(chunk) }
            if decoder.isFinished { finishUpload(sink: sink) }
            return
        }
        let remaining = expectedBody - Int(sink.written)
        if remaining <= 0 {
            finishUpload(sink: sink)
            return
        }
        let take = Swift.min(remaining, data.count)
        if take > 0 { sink.write(Data(data.prefix(take))) }
        if sink.written >= Int64(expectedBody) { finishUpload(sink: sink) }
    }

    private func finishUpload(sink: UploadSink) {
        guard case .streamingUpload = mode else { return }
        let written = sink.finish()
        mode = .done
        if let written {
            server.addTraffic(-written)
            respond(.json(["ok": true, "name": sink.url.lastPathComponent, "size": written]))
        } else {
            sink.abort()
            respond(.json(["ok": false, "error": "写入失败"], status: 500))
        }
    }

    // MARK: - 响应

    private func respond(_ response: HTTPResponse) {
        guard !closed else { return }
        if case .streamingUpload(let sink) = mode {
            sink.abort()
            mode = .done
        }
        mode = .done

        let method = request?.method ?? "GET"
        let headOnly = method == "HEAD" || response.status == 204

        var contentLength: Int64 = 0
        switch response.body {
        case .data(let payload): contentLength = Int64(payload.count)
        case .file(_, _, let length): contentLength = length
        }
        if response.status == 204 { contentLength = 0 }

        var head = "HTTP/1.1 \(response.status) \(HTTPStatus.reason(response.status))\r\n"
        head += "Date: \(HTTPDate.string())\r\n"
        head += "Server: EZShare/1.0\r\n"
        head += "Connection: close\r\n"
        head += "X-Content-Type-Options: nosniff\r\n"
        for (key, value) in response.headers where key.lowercased() != "content-length" {
            head += "\(key): \(value)\r\n"
        }
        head += "Content-Length: \(contentLength)\r\n\r\n"

        var headData = Data(head.utf8)
        if headOnly {
            send(headData) { [weak self] in
                self?.record(status: response.status, bytes: 0)
                self?.close()
            }
            return
        }

        switch response.body {
        case .data(let payload):
            headData.append(payload)
            send(headData) { [weak self] in
                self?.record(status: response.status, bytes: Int64(payload.count))
                self?.close()
            }
        case .file(let url, let offset, let length):
            send(headData) { [weak self] in
                guard let self else { return }
                self.record(status: response.status, bytes: length)
                if length <= 0 {
                    self.close()
                } else {
                    self.streamFile(url: url, offset: offset, length: length)
                }
            }
        }
    }

    private func send(_ data: Data, completion: @escaping () -> Void) {
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if error != nil {
                self?.close()
                return
            }
            completion()
        })
    }

    private func streamFile(url: URL, offset: Int64, length: Int64) {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            close()
            return
        }
        do {
            try handle.seek(toOffset: UInt64(max(0, offset)))
        } catch {
            try? handle.close()
            close()
            return
        }

        var remaining = length
        func pump() {
            guard !closed else {
                try? handle.close()
                return
            }
            if remaining <= 0 {
                try? handle.close()
                close()
                return
            }
            let chunk: Data
            do {
                chunk = try handle.read(upToCount: Int(Swift.min(remaining, 256 * 1024))) ?? Data()
            } catch {
                try? handle.close()
                close()
                return
            }
            if chunk.isEmpty {
                try? handle.close()
                close()
                return
            }
            remaining -= Int64(chunk.count)
            connection.send(content: chunk, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                if error != nil {
                    try? handle.close()
                    self.close()
                    return
                }
                pump()
            })
        }
        pump()
    }

    private func record(status: Int, bytes: Int64) {
        guard let parsed = request else { return }
        let log = AccessLog(
            time: Date(),
            peer: peer,
            method: parsed.method,
            path: parsed.path,
            status: status,
            bytes: bytes
        )
        server.record(log)
        if bytes > 0 { server.addTraffic(bytes) }
    }

    func close() {
        guard !closed else { return }
        closed = true
        if case .streamingUpload(let sink) = mode {
            sink.abort()
            mode = .done
        }
        connection.stateUpdateHandler = nil
        connection.cancel()
        server.finish(connectionID: id)
    }
}

// MARK: - 上传落盘

final class UploadSink {
    let url: URL
    private let handle: FileHandle
    private(set) var written: Int64 = 0
    private var failed = false

    init?(url: URL) {
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else { return nil }
        guard let handle = try? FileHandle(forWritingTo: url) else { return nil }
        self.url = url
        self.handle = handle
    }

    func write(_ data: Data) {
        guard !failed, !data.isEmpty else { return }
        do {
            try handle.write(contentsOf: data)
            written += Int64(data.count)
        } catch {
            failed = true
        }
    }

    func finish() -> Int64? {
        try? handle.synchronize()
        try? handle.close()
        if failed {
            return nil
        }
        return written
    }

    func abort() {
        try? handle.close()
        try? FileManager.default.removeItem(at: url)
    }
}

enum HTTPDate {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter
    }()

    static func string() -> String {
        formatter.string(from: Date())
    }
}
