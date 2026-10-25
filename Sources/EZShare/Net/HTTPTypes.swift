import Foundation

enum HTTPStatus {
    static func reason(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 204: return "No Content"
        case 206: return "Partial Content"
        case 302: return "Found"
        case 304: return "Not Modified"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 409: return "Conflict"
        case 413: return "Payload Too Large"
        case 416: return "Range Not Satisfiable"
        case 431: return "Request Header Fields Too Large"
        case 500: return "Internal Server Error"
        case 501: return "Not Implemented"
        case 507: return "Insufficient Storage"
        default: return code < 400 ? "OK" : "Error"
        }
    }
}

struct HTTPRequest {
    var method: String = ""
    var target: String = ""
    var path: String = ""
    var query: [String: String] = [:]
    var headers: [String: String] = [:]
    var body = Data()

    func header(_ name: String) -> String? {
        headers[name.lowercased()]
    }

    func cookie(_ name: String) -> String? {
        guard let raw = header("cookie") else { return nil }
        for part in raw.split(separator: ";") {
            let pair = part.trimmingCharacters(in: .whitespaces)
            guard let index = pair.firstIndex(of: "=") else { continue }
            let key = String(pair[pair.startIndex..<index])
            if key == name {
                return String(pair[pair.index(after: index)...])
            }
        }
        return nil
    }

    var bodyString: String {
        String(data: body, encoding: .utf8) ?? ""
    }

    var jsonBody: [String: Any] {
        guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return [:] }
        return object
    }
}

enum HTTPBody {
    case data(Data)
    case file(url: URL, offset: Int64, length: Int64)
}

struct HTTPResponse {
    var status: Int = 200
    var headers: [String: String] = [:]
    var body: HTTPBody = .data(Data())

    static func text(_ string: String, status: Int = 200, contentType: String = "text/plain; charset=utf-8") -> HTTPResponse {
        HTTPResponse(
            status: status,
            headers: ["Content-Type": contentType],
            body: .data(Data(string.utf8))
        )
    }

    static func html(_ string: String, status: Int = 200) -> HTTPResponse {
        HTTPResponse(
            status: status,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: .data(Data(string.utf8))
        )
    }

    static func json(_ object: [String: Any], status: Int = 200) -> HTTPResponse {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [])) ?? Data()
        return HTTPResponse(
            status: status,
            headers: ["Content-Type": "application/json; charset=utf-8"],
            body: .data(data)
        )
    }

    static func redirect(_ location: String) -> HTTPResponse {
        HTTPResponse(status: 302, headers: ["Location": location], body: .data(Data()))
    }

    static func empty(status: Int = 204) -> HTTPResponse {
        HTTPResponse(status: status, headers: [:], body: .data(Data()))
    }
}

extension String {
    var urlDecoded: String {
        replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? self
    }

    var urlEncoded: String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}

enum HTTPParser {
    /// 解析请求行与头部。返回 nil 表示格式非法。
    static func parseHead(_ text: String) -> (HTTPRequest, Int)? {
        let lines = text.components(separatedBy: "\r\n")
        guard let requestLine = lines.first, !requestLine.isEmpty else { return nil }

        let parts = requestLine.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return nil }

        var request = HTTPRequest()
        request.method = String(parts[0]).uppercased()
        request.target = String(parts[1])

        var contentLength = 0
        for line in lines.dropFirst() where !line.isEmpty {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[line.startIndex..<colon]).lowercased()
            var value = String(line[line.index(after: colon)...])
            if value.hasPrefix(" ") { value.removeFirst() }
            if key == "content-length" {
                contentLength = Int(value) ?? 0
            }
            if let existing = request.headers[key] {
                request.headers[key] = existing + ", " + value
            } else {
                request.headers[key] = value
            }
        }

        if let questionMark = request.target.firstIndex(of: "?") {
            request.path = String(request.target[request.target.startIndex..<questionMark])
            let queryString = String(request.target[request.target.index(after: questionMark)...])
            for pair in queryString.split(separator: "&", omittingEmptySubsequences: true) {
                let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                let key = String(kv[0]).urlDecoded
                let value = kv.count > 1 ? String(kv[1]).urlDecoded : ""
                request.query[key] = value
            }
        } else {
            request.path = request.target
        }

        return (request, contentLength)
    }

    static func formBody(_ string: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in string.split(separator: "&", omittingEmptySubsequences: true) {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let key = String(kv[0]).urlDecoded
            result[key] = kv.count > 1 ? String(kv[1]).urlDecoded : ""
        }
        return result
    }
}

/// 增量解析 Transfer-Encoding: chunked。
final class ChunkedDecoder {
    private enum Phase {
        case size
        case payload
        case terminator
    }

    private var buffer = Data()
    private var phase: Phase = .size
    private var remaining = 0
    private var finished = false

    var isFinished: Bool { finished }

    func feed(_ data: Data, emit: (Data) -> Void) {
        buffer.append(data)
        while !finished {
            switch phase {
            case .size:
                guard let lineEnd = buffer.range(of: Data("\r\n".utf8)) else { return }
                let lineData = buffer.subdata(in: buffer.startIndex..<lineEnd.lowerBound)
                buffer.removeSubrange(buffer.startIndex..<lineEnd.upperBound)
                let line = String(data: lineData, encoding: .utf8) ?? ""
                let hex = line.split(separator: ";").first.map(String.init) ?? "0"
                guard let size = Int(hex.trimmingCharacters(in: .whitespaces), radix: 16), size >= 0 else {
                    finished = true
                    return
                }
                if size == 0 {
                    finished = true
                    return
                }
                remaining = size
                phase = .payload
            case .payload:
                guard !buffer.isEmpty else { return }
                let take = Swift.min(remaining, buffer.count)
                let chunk = buffer.subdata(in: buffer.startIndex..<(buffer.startIndex + take))
                buffer.removeSubrange(buffer.startIndex..<(buffer.startIndex + take))
                remaining -= take
                if !chunk.isEmpty { emit(chunk) }
                if remaining == 0 { phase = .terminator }
            case .terminator:
                guard buffer.count >= 2 else { return }
                buffer.removeSubrange(buffer.startIndex..<(buffer.startIndex + 2))
                phase = .size
            }
        }
    }
}
