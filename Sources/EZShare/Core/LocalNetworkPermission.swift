import Foundation
import Network

/// 本地网络权限（macOS 15+ 的「本地网络」隐私开关）。
///
/// - `triggerPrompt()`：用 Bonjour 浏览主动触发系统授权弹窗（仅 macOS 15+ 会弹）。
/// - `check()`：向默认网关发起 TCP 连接探测，判断权限是否被拒绝。
///   网关通常不监听 9 端口，若协议栈放行会立刻返回「拒绝连接」→ 已授权；
///   若被隐私开关拦截，连接会长时间停在 waiting → 判定为被拒绝。
enum LocalNetworkPermission {
    enum Status: Equatable {
        case checking
        case granted
        case denied
        case unknown
    }

    private static let probeService = "_ezshare._tcp."
    private static var triggerBrowser: NWBrowser?

    /// 主动触发系统「本地网络」授权弹窗（无权限时系统自动弹出）。
    static func triggerPrompt() {
        let params = NWParameters()
        params.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: probeService, domain: "local."), using: params)
        browser.stateUpdateHandler = { _ in }
        browser.browseResultsChangedHandler = { _, _ in }
        browser.start(queue: .global(qos: .utility))
        triggerBrowser = browser
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak browser] in
            browser?.cancel()
            if triggerBrowser === browser { triggerBrowser = nil }
        }
    }

    /// 探测本地网络访问是否被拒绝。结果在主线程回调。
    static func check(timeout: TimeInterval = 4, completion: @escaping (Status) -> Void) {
        guard let gateway = defaultGateway() else {
            DispatchQueue.main.async { completion(.unknown) }
            return
        }

        let conn = NWConnection(host: NWEndpoint.Host(gateway), port: 9, using: .tcp)
        let box = OnceBox()

        let finish: (Status) -> Void = { status in
            guard box.mark() else { return }
            conn.stateUpdateHandler = nil
            conn.cancel()
            DispatchQueue.main.async { completion(status) }
        }

        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                finish(.granted)
            case .failed(let error):
                // 立刻被拒绝连接 = 协议栈正常放行到网关，权限没问题
                if case .posix(.ECONNREFUSED) = error {
                    finish(.granted)
                } else {
                    finish(.unknown)
                }
            case .waiting:
                // 网络可达但连接被静默拦截，是本地网络权限被拒的典型表现
                finish(.denied)
            default:
                break
            }
        }

        conn.start(queue: .global(qos: .utility))
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            finish(.unknown)
        }
    }

    /// 读取默认网关地址。
    private static func defaultGateway() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/route")
        task.arguments = ["-n", "get", "default"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard task.terminationStatus == 0,
              let out = String(data: data, encoding: .utf8) else { return nil }
        for line in out.split(separator: "\n") {
            let parts = line.split(separator: " ").map(String.init)
            if let i = parts.firstIndex(of: "gateway:"), i + 1 < parts.count {
                return parts[i + 1]
            }
        }
        return nil
    }
}

private final class OnceBox {
    private let lock = NSLock()
    private var done = false
    func mark() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}
