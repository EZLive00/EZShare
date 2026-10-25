import Foundation

enum PathResolver {
    /// 把 URL 中的相对路径解析成共享目录内的绝对路径；越界返回 nil。
    static func resolve(_ relative: String, in root: URL) -> URL? {
        let rootPath = root.standardizedFileURL.path
        var url = root
        for component in relative.split(separator: "/", omittingEmptySubsequences: true) {
            let piece = String(component)
            if piece == "." { continue }
            if piece == ".." { return nil }
            url.appendPathComponent(piece)
        }
        let target = url.standardizedFileURL.path
        guard target == rootPath || target.hasPrefix(rootPath + "/") else { return nil }
        return url
    }

    /// 计算文件相对于共享目录的路径（不带前导斜杠）。
    static func relativePath(of url: URL, in root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let target = url.standardizedFileURL.path
        guard target.hasPrefix(rootPath) else { return "" }
        var rel = String(target.dropFirst(rootPath.count))
        while rel.hasPrefix("/") { rel.removeFirst() }
        return rel
    }

    /// 清洗上传 / 新建时使用的单个名称，禁止路径分隔符与隐藏的目录跳转。
    static func sanitizeName(_ raw: String) -> String? {
        var name = raw.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if name == "." || name == ".." { return nil }
        if name.isEmpty { return nil }
        if name.count > 200 { name = String(name.prefix(200)) }
        return name
    }

    /// 目标已存在时生成 "name (1).ext" 形式的唯一路径。
    static func uniqueURL(for name: String, in directory: URL) -> URL {
        let fm = FileManager.default
        let candidate = directory.appendingPathComponent(name)
        if !fm.fileExists(atPath: candidate.path) { return candidate }

        let ext = (name as NSString).pathExtension
        let base = ext.isEmpty ? name : (name as NSString).deletingPathExtension
        var index = 1
        while index < 10_000 {
            let next = ext.isEmpty ? "\(base) (\(index))" : "\(base) (\(index)).\(ext)"
            let url = directory.appendingPathComponent(next)
            if !fm.fileExists(atPath: url.path) { return url }
            index += 1
        }
        return directory.appendingPathComponent(UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)"))
    }
}

struct FileEntry {
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modified: Date
}

enum FileLister {
    static func entries(in directory: URL) -> [FileEntry] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let entries: [FileEntry] = contents.compactMap { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            let isDir = values?.isDirectory ?? false
            return FileEntry(
                name: url.lastPathComponent,
                isDirectory: isDir,
                size: Int64(values?.fileSize ?? 0),
                modified: values?.contentModificationDate ?? Date(timeIntervalSince1970: 0)
            )
        }
        return entries.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
