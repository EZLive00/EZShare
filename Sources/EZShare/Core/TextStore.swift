import Foundation

struct TextSnippet: Codable {
    let id: String
    let content: String
    let createdAt: Date
}

/// 文本共享存储：JSON 持久化到 Application Support，跨重启保留。
final class TextStore {
    static let shared = TextStore()

    private let lock = NSLock()
    private var items: [TextSnippet] = []
    private let fileURL: URL
    private let maxItems = 200
    private let maxSnippetLength = 1_000_000

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("EZShare", isDirectory: true)
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appendingPathComponent("texts.json")
        load()
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return items.count
    }

    func list() -> [TextSnippet] {
        lock.lock()
        defer { lock.unlock() }
        return items
    }

    func find(id: String) -> TextSnippet? {
        lock.lock()
        defer { lock.unlock() }
        return items.first { $0.id == id }
    }

    @discardableResult
    func add(_ raw: String) -> TextSnippet? {
        let content = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, content.count <= maxSnippetLength else { return nil }

        lock.lock()
        let snippet = TextSnippet(id: UUID().uuidString, content: content, createdAt: Date())
        items.insert(snippet, at: 0)
        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }
        persistLocked()
        lock.unlock()
        return snippet
    }

    @discardableResult
    func remove(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        items.remove(at: index)
        persistLocked()
        return true
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([TextSnippet].self, from: data) else { return }
        items = decoded
    }

    private func persistLocked() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(items) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
