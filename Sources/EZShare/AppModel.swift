import Foundation
import AppKit
import Combine

struct TransferStats {
    var requests: Int = 0
    var bytesOut: Int64 = 0
    var bytesIn: Int64 = 0
}

/// 共享目录中的一个条目（供原生界面浏览）。
struct ShareEntry: Identifiable, Equatable {
    let id: String          // 相对路径
    let name: String
    let relativePath: String
    let isDirectory: Bool
    let size: Int64
    let modified: Date
}

final class AppModel: ObservableObject {
    private enum Keys {
        static let sharePath = "sharePath"
        static let port = "port"
        static let allowUpload = "allowUpload"
        static let allowDelete = "allowDelete"
        static let requireCode = "requireCode"
        static let accessCode = "accessCode"
    }

    @Published private(set) var isRunning = false
    @Published private(set) var isStarting = false
    @Published private(set) var boundPort: Int
    @Published private(set) var addresses: [String] = []
    @Published private(set) var logs: [AccessLog] = []
    @Published private(set) var stats = TransferStats()
    @Published private(set) var folderItemCount = 0
    @Published private(set) var textCount = 0
    @Published private(set) var statusText = "未启动"
    @Published private(set) var localNetworkStatus: LocalNetworkPermission.Status = .unknown
    @Published private(set) var fileEntries: [ShareEntry] = []
    @Published private(set) var snippets: [TextSnippet] = []

    /// 原生界面的当前浏览子目录（相对共享目录，空 = 根）。
    @Published var browsePath: String = "" {
        didSet { refreshFileEntries() }
    }

    @Published var shareDirectory: URL {
        didSet {
            UserDefaults.standard.set(shareDirectory.path, forKey: Keys.sharePath)
            syncConfig()
            refreshFolderInfo()
            browsePath = ""
            refreshContent()
        }
    }

    @Published var port: Int {
        didSet {
            let clamped = min(max(port, 1024), 65_535)
            if clamped != port { port = clamped; return }
            UserDefaults.standard.set(port, forKey: Keys.port)
        }
    }

    @Published var allowUpload: Bool {
        didSet { UserDefaults.standard.set(allowUpload, forKey: Keys.allowUpload); syncConfig() }
    }

    @Published var allowDelete: Bool {
        didSet { UserDefaults.standard.set(allowDelete, forKey: Keys.allowDelete); syncConfig() }
    }

    @Published var requireCode: Bool {
        didSet { UserDefaults.standard.set(requireCode, forKey: Keys.requireCode); syncConfig() }
    }

    @Published var accessCode: String {
        didSet { UserDefaults.standard.set(accessCode, forKey: Keys.accessCode); syncConfig() }
    }

    private var server: HTTPServer?
    private let config: ConfigStore

    init() {
        let defaults = UserDefaults.standard
        let fallback = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads/EZShare", isDirectory: true)

        let savedPath = defaults.string(forKey: Keys.sharePath) ?? ""
        let directory = savedPath.isEmpty ? fallback : URL(fileURLWithPath: savedPath, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let upload = defaults.object(forKey: Keys.allowUpload) as? Bool ?? true
        let deletion = defaults.object(forKey: Keys.allowDelete) as? Bool ?? false
        let protection = defaults.bool(forKey: Keys.requireCode)
        let savedCode = defaults.string(forKey: Keys.accessCode) ?? ""
        // 旧版本的 4 位数字码自动升级为 6 位字母数字混合码
        let isLegacyNumeric = savedCode.count == 4 && savedCode.allSatisfy(\.isNumber)
        let code = savedCode.isEmpty || isLegacyNumeric ? Self.generateCode() : savedCode
        let savedPort = defaults.integer(forKey: Keys.port)
        let chosenPort = savedPort == 0 ? 8080 : savedPort

        shareDirectory = directory
        port = chosenPort
        allowUpload = upload
        allowDelete = deletion
        requireCode = protection
        accessCode = code
        boundPort = chosenPort
        config = ConfigStore(
            ShareSettings(
                rootPath: directory.path,
                allowUpload: upload,
                allowDelete: deletion,
                requireCode: protection,
                accessCode: code
            )
        )

        refreshAddresses()
        refreshFolderInfo()
        refreshContent()
        probeLocalNetwork()
    }

    // MARK: - 派生状态

    var displayPort: Int { isRunning ? boundPort : port }

    var urls: [String] {
        addresses.map { "http://\($0):\(displayPort)" }
    }

    var primaryURL: String? { urls.first }

    var shareName: String {
        let name = shareDirectory.lastPathComponent
        return name.isEmpty ? "EZShare" : name
    }

    var hasAddress: Bool { !addresses.isEmpty }

    /// 生成 6 位字母数字混合访问码。
    /// 剔除易混淆字符（0/O/o、1/l/I），并保证字母和数字至少各含一个。
    private static func generateCode() -> String {
        let digits = Array("23456789")
        let letters = Array("abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ")
        let alphabet = digits + letters
        var code: String
        repeat {
            code = String((0..<6).map { _ in alphabet.randomElement()! })
        } while !code.contains(where: digits.contains) || !code.contains(where: letters.contains)
        return code
    }

    // MARK: - 控制

    func toggle() {
        if isRunning || isStarting {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard !isRunning, !isStarting else { return }
        syncConfig()
        probeLocalNetwork()

        let router = Router(config: config)
        let server = HTTPServer(router: router)
        server.onState = { [weak self] state in self?.apply(state) }
        server.onLog = { [weak self] log in self?.append(log) }
        server.onTraffic = { [weak self] delta in self?.addTraffic(delta) }
        self.server = server

        isStarting = true
        statusText = "正在启动…"
        server.start(preferredPort: UInt16(clamping: port))
    }

    func stop() {
        isStarting = false
        server?.stop()
        server = nil
        isRunning = false
        statusText = "已停止"
        boundPort = port
    }

    func clearLogs() {
        logs.removeAll()
        stats = TransferStats()
    }

    // MARK: - 目录

    func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "共享此文件夹"
        panel.message = "选择要共享到局域网的文件夹"
        panel.directoryURL = shareDirectory
        if panel.runModal() == .OK, let url = panel.url {
            shareDirectory = url
        }
    }

    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([shareDirectory])
    }

    func openInBrowser(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func randomizeCode() {
        accessCode = Self.generateCode()
    }

    // MARK: - 内部

    private func syncConfig() {
        config.update(
            ShareSettings(
                rootPath: shareDirectory.path,
                allowUpload: allowUpload,
                allowDelete: allowDelete,
                requireCode: requireCode,
                accessCode: accessCode
            )
        )
    }

    private func apply(_ state: HTTPServer.State) {
        switch state {
        case .idle:
            isRunning = false
            isStarting = false
            boundPort = port
            statusText = "已停止"
        case .starting:
            isStarting = true
            statusText = "正在启动…"
        case .running(let actualPort):
            isRunning = true
            isStarting = false
            boundPort = Int(actualPort)
            if Int(actualPort) == port {
                statusText = "正在共享"
            } else {
                statusText = "端口 \(port) 被占用，已改用 \(actualPort)"
            }
            refreshAddresses()
        case .failed(let message):
            isRunning = false
            isStarting = false
            statusText = "启动失败：\(message)"
        }
    }

    private func append(_ log: AccessLog) {
        logs.insert(log, at: 0)
        if logs.count > 60 { logs.removeLast(logs.count - 60) }
        stats.requests += 1
    }

    private func addTraffic(_ delta: Int64) {
        if delta >= 0 {
            stats.bytesOut += delta
        } else {
            stats.bytesIn += -delta
        }
    }

    func refreshAddresses() {
        let next = NetworkInfo.ipv4().map { $0.ip }
        if next != addresses { addresses = next }
    }

    func refreshFolderInfo() {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: shareDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        folderItemCount = contents.count
    }

    func refreshTextCount() {
        textCount = TextStore.shared.count
    }

    // MARK: - 共享内容浏览（原生界面）

    func refreshContent() {
        refreshFileEntries()
        snippets = TextStore.shared.list()
        refreshTextCount()
    }

    private func refreshFileEntries() {
        let base = browsePath.isEmpty
            ? shareDirectory
            : shareDirectory.appendingPathComponent(browsePath, isDirectory: true)
        let items = (try? FileManager.default.contentsOfDirectory(
            at: base,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        let entries: [ShareEntry] = items.map { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            let relative = browsePath.isEmpty
                ? url.lastPathComponent
                : browsePath + "/" + url.lastPathComponent
            return ShareEntry(
                id: relative,
                name: url.lastPathComponent,
                relativePath: relative,
                isDirectory: values?.isDirectory ?? false,
                size: Int64(values?.fileSize ?? 0),
                modified: values?.contentModificationDate ?? Date()
            )
        }
        .sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
        if entries != fileEntries { fileEntries = entries }
    }

    func url(for entry: ShareEntry) -> URL {
        shareDirectory.appendingPathComponent(entry.relativePath)
    }

    func openEntry(_ entry: ShareEntry) {
        if entry.isDirectory {
            browsePath = entry.relativePath
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([url(for: entry)])
        }
    }

    func revealEntry(_ entry: ShareEntry) {
        NSWorkspace.shared.activateFileViewerSelecting([url(for: entry)])
    }

    func goUp() {
        let parts = browsePath.split(separator: "/").map(String.init)
        browsePath = parts.dropLast().joined(separator: "/")
    }

    var browseDisplayName: String {
        let parts = browsePath.split(separator: "/").map(String.init)
        return parts.last ?? shareName
    }

    func copySnippet(_ snippet: TextSnippet) {
        copy(snippet.content)
    }

    func deleteSnippet(_ snippet: TextSnippet) {
        _ = TextStore.shared.remove(id: snippet.id)
        refreshContent()
    }

    /// 触发系统「本地网络」授权弹窗并探测权限状态（结果主线程回调）。
    func probeLocalNetwork() {
        localNetworkStatus = .checking
        LocalNetworkPermission.triggerPrompt()
        LocalNetworkPermission.check { [weak self] status in
            self?.localNetworkStatus = status == .checking ? .unknown : status
        }
    }
}
