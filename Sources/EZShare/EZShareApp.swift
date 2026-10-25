import SwiftUI
import AppKit

@main
enum Launcher {
    static func main() {
        if CommandLine.arguments.contains("--headless") {
            HeadlessRunner.run()
        } else {
            EZShareApp.main()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct EZShareApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("EZShare") {
            ContentView()
                .environmentObject(model)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("共享") {
                Button(model.isRunning ? "停止共享" : "启动共享") {
                    model.toggle()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("在浏览器中打开") {
                    if let url = model.primaryURL { model.openInBrowser(url) }
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(model.primaryURL == nil)

                Button("复制访问地址") {
                    if let url = model.primaryURL { model.copy(url) }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(model.primaryURL == nil)

                Divider()

                Button("在访达中显示共享目录") {
                    model.revealInFinder()
                }
            }
        }
    }
}

/// 命令行模式：便于在终端或 CI 中直接验证 HTTP 服务。
enum HeadlessRunner {
    private static var keepAlive: HTTPServer?

    static func run() {
        var root = FileManager.default.currentDirectoryPath
        var port: UInt16 = 8080
        var requireCode = false
        var code = ""

        let arguments = CommandLine.arguments
        var index = 1
        while index < arguments.count {
            switch arguments[index] {
            case "--root" where index + 1 < arguments.count:
                root = arguments[index + 1]
                index += 1
            case "--port" where index + 1 < arguments.count:
                port = UInt16(arguments[index + 1]) ?? port
                index += 1
            case "--code" where index + 1 < arguments.count:
                requireCode = true
                code = arguments[index + 1]
                index += 1
            default:
                break
            }
            index += 1
        }

        let settings = ShareSettings(
            rootPath: root,
            allowUpload: true,
            allowDelete: true,
            requireCode: requireCode,
            accessCode: code
        )
        let server = HTTPServer(router: Router(config: ConfigStore(settings)))
        server.onLog = { log in
            print("[\(log.status)] \(log.method) \(log.path) \(log.bytes)B \(log.peer)")
        }
        server.onState = { state in
            switch state {
            case .running(let port):
                print("EZShare listening on http://0.0.0.0:\(port) root=\(root)")
            case .failed(let message):
                print("EZShare failed: \(message)")
                exit(1)
            default:
                break
            }
        }
        keepAlive = server
        server.start(preferredPort: port)
        RunLoop.main.run()
    }
}
