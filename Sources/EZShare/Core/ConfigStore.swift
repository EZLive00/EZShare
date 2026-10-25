import Foundation

/// 运行时可变配置。UI 线程写入，HTTP 线程读取，用锁保护。
final class ConfigStore {
    private let lock = NSLock()
    private var settings: ShareSettings

    init(_ settings: ShareSettings) {
        self.settings = settings
    }

    func snapshot() -> ShareSettings {
        lock.lock()
        defer { lock.unlock() }
        return settings
    }

    func update(_ settings: ShareSettings) {
        lock.lock()
        self.settings = settings
        lock.unlock()
    }
}

struct ShareSettings: Equatable {
    var rootPath: String
    var allowUpload: Bool
    var allowDelete: Bool
    var requireCode: Bool
    var accessCode: String

    var rootURL: URL {
        URL(fileURLWithPath: rootPath, isDirectory: true)
    }

    var shareName: String {
        let name = rootURL.lastPathComponent
        return name.isEmpty ? "EZShare" : name
    }
}
