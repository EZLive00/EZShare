import Foundation

struct AccessLog {
    let time: Date
    let peer: String
    let method: String
    let path: String
    let status: Int
    let bytes: Int64
}

enum UploadPlan {
    case reject(HTTPResponse)
    case stream(fileURL: URL, displayName: String)
}

final class Router {
    private let config: ConfigStore
    private var sessions = Set<String>()
    private let lock = NSLock()

    init(config: ConfigStore) {
        self.config = config
    }

    // MARK: - 入口

    func handle(_ request: HTTPRequest) -> HTTPResponse {
        let settings = config.snapshot()

        switch request.path {
        case "/favicon.ico":
            return .empty()
        case "/health":
            return .text("ok")
        case "/login":
            if request.method == "POST" { return handleLogin(request, settings: settings) }
            return .html(WebUI.login(error: nil, shareName: settings.shareName))
        case "/logout":
            lock.lock()
            if let token = request.cookie("ezshare_token") { sessions.remove(token) }
            lock.unlock()
            return HTTPResponse(
                status: 302,
                headers: [
                    "Location": "/login",
                    "Set-Cookie": "ezshare_token=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax"
                ],
                body: .data(Data())
            )
        default:
            break
        }

        guard authorized(request) else {
            if prefersHTML(request) { return .redirect("/login") }
            return .json(["ok": false, "error": "需要访问码"], status: 401)
        }

        switch request.path {
        case "/":
            return handleListing(request, settings: settings)
        case "/download":
            return handleDownload(request, settings: settings)
        case "/api/mkdir":
            return handleMkdir(request, settings: settings)
        case "/api/delete":
            return handleDelete(request, settings: settings)
        case "/api/upload":
            return .json(["ok": false, "error": "上传需使用流式请求"], status: 400)
        default:
            return .html(WebUI.errorPage(status: 404, message: "找不到这个地址"), status: 404)
        }
    }

    /// 上传请求需要在连接层流式写入磁盘，这里先做鉴权与目标解析。
    func uploadPlan(for request: HTTPRequest) -> UploadPlan {
        let settings = config.snapshot()
        guard authorized(request) else {
            return .reject(.json(["ok": false, "error": "需要访问码"], status: 401))
        }
        guard settings.allowUpload else {
            return .reject(.json(["ok": false, "error": "共享端已关闭上传"], status: 403))
        }
        guard let rawName = request.query["name"], let name = PathResolver.sanitizeName(rawName) else {
            return .reject(.json(["ok": false, "error": "文件名无效"], status: 400))
        }
        let directoryRelative = request.query["dir"] ?? ""
        guard let directory = PathResolver.resolve(directoryRelative, in: settings.rootURL) else {
            return .reject(.json(["ok": false, "error": "目录越界"], status: 403))
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .reject(.json(["ok": false, "error": "目标目录不存在"], status: 404))
        }
        let fileURL = PathResolver.uniqueURL(for: name, in: directory)
        return .stream(fileURL: fileURL, displayName: fileURL.lastPathComponent)
    }

    // MARK: - 鉴权

    private func authorized(_ request: HTTPRequest) -> Bool {
        let settings = config.snapshot()
        guard settings.requireCode, !settings.accessCode.isEmpty else { return true }
        guard let token = request.cookie("ezshare_token"), !token.isEmpty else { return false }
        lock.lock()
        defer { lock.unlock() }
        return sessions.contains(token)
    }

    private func prefersHTML(_ request: HTTPRequest) -> Bool {
        (request.header("accept") ?? "").contains("text/html")
    }

    private func handleLogin(_ request: HTTPRequest, settings: ShareSettings) -> HTTPResponse {
        let form = HTTPParser.formBody(request.bodyString)
        let code = (form["code"] ?? "").trimmingCharacters(in: .whitespaces)
        guard !settings.accessCode.isEmpty, code == settings.accessCode else {
            return .html(WebUI.login(error: "访问码不正确", shareName: settings.shareName), status: 401)
        }
        let token = UUID().uuidString
        lock.lock()
        sessions.insert(token)
        lock.unlock()
        return HTTPResponse(
            status: 302,
            headers: [
                "Location": "/",
                "Set-Cookie": "ezshare_token=\(token); Path=/; HttpOnly; SameSite=Lax"
            ],
            body: .data(Data())
        )
    }

    // MARK: - 目录

    private func handleListing(_ request: HTTPRequest, settings: ShareSettings) -> HTTPResponse {
        let relative = (request.query["path"] ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let target = PathResolver.resolve(relative, in: settings.rootURL) else {
            return .html(WebUI.errorPage(status: 403, message: "路径超出共享目录"), status: 403)
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: target.path, isDirectory: &isDirectory) else {
            return .html(WebUI.errorPage(status: 404, message: "目录不存在"), status: 404)
        }
        if !isDirectory.boolValue {
            return fileResponse(target, request: request)
        }
        let entries = FileLister.entries(in: target)
        let normalized = PathResolver.relativePath(of: target, in: settings.rootURL)
        let html = WebUI.listing(relativePath: normalized, entries: entries, settings: settings)
        return .html(html)
    }

    private func handleDownload(_ request: HTTPRequest, settings: ShareSettings) -> HTTPResponse {
        guard let relative = request.query["path"], !relative.isEmpty else {
            return .html(WebUI.errorPage(status: 400, message: "缺少 path 参数"), status: 400)
        }
        guard let target = PathResolver.resolve(relative, in: settings.rootURL) else {
            return .html(WebUI.errorPage(status: 403, message: "路径超出共享目录"), status: 403)
        }
        return fileResponse(target, request: request)
    }

    private func fileResponse(_ url: URL, request: HTTPRequest) -> HTTPResponse {
        let manager = FileManager.default
        var isDirectory: ObjCBool = false
        guard manager.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return .html(WebUI.errorPage(status: 404, message: "文件不存在"), status: 404)
        }
        let size = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)

        var headers: [String: String] = [
            "Content-Type": MimeType.of(url),
            "Accept-Ranges": "bytes",
            "Content-Disposition": disposition(for: url)
        ]

        var start: Int64 = 0
        var end: Int64 = size > 0 ? size - 1 : 0
        var status = 200

        if let rawRange = request.header("range"),
           let parsed = parseRange(rawRange, size: size) {
            start = parsed.0
            end = parsed.1
            status = 206
            headers["Content-Range"] = "bytes \(start)-\(end)/\(size)"
        } else if request.header("range") != nil && size > 0 {
            return HTTPResponse(
                status: 416,
                headers: ["Content-Range": "bytes */\(size)"],
                body: .data(Data())
            )
        }

        let length = size == 0 ? 0 : end - start + 1
        headers["Content-Length"] = "\(length)"
        return HTTPResponse(
            status: status,
            headers: headers,
            body: .file(url: url, offset: start, length: length)
        )
    }

    private func disposition(for url: URL) -> String {
        let name = url.lastPathComponent
        let inlineTypes: Set<String> = ["image", "video", "audio"]
        let type = MimeType.of(url)
        let inline = inlineTypes.contains(where: { type.hasPrefix($0) }) || type.hasPrefix("text/plain") || type.hasPrefix("application/pdf")
        let mode = inline ? "inline" : "attachment"

        let ascii = name.unicodeScalars.map { scalar -> Character in
            scalar.isASCII && scalar.value >= 32 && scalar.value < 127 && scalar != "\"" ? Character(scalar) : "_"
        }
        let fallback = String(ascii)
        return "\(mode); filename=\"\(fallback)\"; filename*=UTF-8''\(name.urlEncoded)"
    }

    private func parseRange(_ header: String, size: Int64) -> (Int64, Int64)? {
        guard size > 0, header.lowercased().hasPrefix("bytes=") else { return nil }
        let spec = header.dropFirst(6).split(separator: ",").first.map(String.init) ?? ""
        let parts = spec.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }

        let startText = String(parts[0]).trimmingCharacters(in: .whitespaces)
        let endText = String(parts[1]).trimmingCharacters(in: .whitespaces)

        if startText.isEmpty {
            guard let suffix = Int64(endText), suffix > 0 else { return nil }
            let start = max(0, size - suffix)
            return (start, size - 1)
        }
        guard let start = Int64(startText), start < size else { return nil }
        if endText.isEmpty { return (start, size - 1) }
        guard let end = Int64(endText), end >= start else { return nil }
        return (start, min(end, size - 1))
    }

    // MARK: - 写操作

    private func handleMkdir(_ request: HTTPRequest, settings: ShareSettings) -> HTTPResponse {
        guard settings.allowUpload else {
            return .json(["ok": false, "error": "共享端已关闭写入"], status: 403)
        }
        let body = request.jsonBody
        guard let name = PathResolver.sanitizeName(body["name"] as? String ?? "") else {
            return .json(["ok": false, "error": "文件夹名称无效"], status: 400)
        }
        let relative = body["dir"] as? String ?? ""
        guard let parent = PathResolver.resolve(relative, in: settings.rootURL) else {
            return .json(["ok": false, "error": "目录越界"], status: 403)
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: parent.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .json(["ok": false, "error": "上级目录不存在"], status: 404)
        }
        let target = parent.appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: target.path) else {
            return .json(["ok": false, "error": "同名项目已存在"], status: 409)
        }
        do {
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
            return .json(["ok": true])
        } catch {
            return .json(["ok": false, "error": error.localizedDescription], status: 500)
        }
    }

    private func handleDelete(_ request: HTTPRequest, settings: ShareSettings) -> HTTPResponse {
        guard settings.allowDelete else {
            return .json(["ok": false, "error": "共享端已关闭删除"], status: 403)
        }
        let relative = (request.jsonBody["path"] as? String ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !relative.isEmpty else {
            return .json(["ok": false, "error": "不能删除共享根目录"], status: 400)
        }
        guard let target = PathResolver.resolve(relative, in: settings.rootURL) else {
            return .json(["ok": false, "error": "路径越界"], status: 403)
        }
        guard FileManager.default.fileExists(atPath: target.path) else {
            return .json(["ok": false, "error": "项目不存在"], status: 404)
        }
        do {
            try FileManager.default.trashItem(at: target, resultingItemURL: nil)
            return .json(["ok": true])
        } catch {
            return .json(["ok": false, "error": error.localizedDescription], status: 500)
        }
    }
}
