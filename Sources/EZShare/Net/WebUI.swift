import Foundation

enum WebUI {
    // MARK: - 基础元素

    static let brandMark = """
    <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">\
    <path d="M12 15.5V4"/><path d="M7.8 8.2L12 4l4.2 4.2"/>\
    <path d="M4.6 14v4.2a1.9 1.9 0 0 0 1.9 1.9h11a1.9 1.9 0 0 0 1.9-1.9V14"/></svg>
    """

    static func esc(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    static func sizeText(_ bytes: Int64) -> String {
        if bytes <= 0 { return "0 B" }
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var index = 0
        while value >= 1024 && index < units.count - 1 {
            value /= 1024
            index += 1
        }
        if index == 0 { return "\(bytes) B" }
        return String(format: value >= 100 ? "%.0f %@" : "%.1f %@", value, units[index])
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    static func dateText(_ date: Date) -> String {
        date.timeIntervalSince1970 < 1 ? "—" : dateFormatter.string(from: date)
    }

    // MARK: - 图标

    private static let icons: [MimeType.Category: String] = [
        .folder: #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7.5A2 2 0 0 1 5 5.5h3.6c.5 0 1 .2 1.4.6l1 1c.4.4.9.6 1.4.6H19a2 2 0 0 1 2 2v7.8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/></svg>"#,
        .image: #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3.5" y="4.5" width="17" height="15" rx="2.6"/><circle cx="8.8" cy="9.8" r="1.5"/><path d="M4.6 17.2l4.1-4.1a1.6 1.6 0 0 1 2.3 0l2.8 2.8"/><path d="M14.4 15.2l1.7-1.7a1.6 1.6 0 0 1 2.3 0l1.1 1.1"/></svg>"#,
        .video: #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3.5" y="5.5" width="17" height="13" rx="2.6"/><path d="M10.4 9.4l4.6 2.6-4.6 2.6z" fill="currentColor" stroke="none"/></svg>"#,
        .audio: #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M9.5 17.5V7.4l7.5-1.4v9.6"/><circle cx="7.2" cy="17.8" r="2.3"/><circle cx="14.7" cy="16.2" r="2.3"/></svg>"#,
        .archive: #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3.5" y="4.5" width="17" height="15" rx="2.6"/><path d="M3.5 9.5h17"/><path d="M10.4 13.4h3.2"/></svg>"#,
        .code: #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M9.2 8.4L5.6 12l3.6 3.6"/><path d="M14.8 8.4L18.4 12l-3.6 3.6"/><path d="M13 6.6l-2 10.8"/></svg>"#,
        .document: #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M13.4 3.6H7a2 2 0 0 0-2 2v12.8a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V9.2z"/><path d="M13.4 3.6V9.2H19"/><path d="M8.6 13.2h6.8M8.6 16.2h4.2"/></svg>"#,
        .file: #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M13.4 3.6H7a2 2 0 0 0-2 2v12.8a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V9.2z"/><path d="M13.4 3.6V9.2H19"/></svg>"#
    ]

    static func icon(for category: MimeType.Category) -> String {
        icons[category] ?? icons[.file]!
    }

    private static let downloadIcon = #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4.5v10"/><path d="M8 11l4 3.5 4-3.5"/><path d="M5 18.5h14"/></svg>"#
    private static let trashIcon = #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4.8 7h14.4"/><path d="M9.4 7V5.4a1.4 1.4 0 0 1 1.4-1.4h2.4a1.4 1.4 0 0 1 1.4 1.4V7"/><path d="M6.6 7l.8 11.2a1.8 1.8 0 0 0 1.8 1.6h5.6a1.8 1.8 0 0 0 1.8-1.6L17.4 7"/></svg>"#
    private static let copyIcon = #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="11" height="11" rx="2.2"/><path d="M5.5 14.5A1.8 1.8 0 0 1 4 12.7V5.8A1.8 1.8 0 0 1 5.8 4h6.9a1.8 1.8 0 0 1 1.8 1.5"/></svg>"#
    private static let refreshIcon = #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12a7 7 0 1 1-2-4.9"/><path d="M19 4.5V8h-3.5"/></svg>"#
    private static let searchIcon = #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="6.2"/><path d="M16 16l3.4 3.4"/></svg>"#
    private static let plusIcon = #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"><path d="M12 5.5v13M5.5 12h13"/></svg>"#
    private static let uploadIcon = #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 16V5"/><path d="M7.8 9.2L12 5l4.2 4.2"/><path d="M5 18.5h14"/></svg>"#
    private static let emptyIcon = #"<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M3.5 8.5A2 2 0 0 1 5.5 6.5h3.2c.5 0 1 .2 1.3.5l.9.9c.3.3.8.5 1.3.5h6.3a2 2 0 0 1 2 2v6.2a2 2 0 0 1-2 2h-13a2 2 0 0 1-2-2z"/></svg>"#

    // MARK: - 页面骨架

    static func shell(title: String, bodyAttributes: String, content: String, includeScript: Bool) -> String {
        """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
        <meta name="color-scheme" content="light dark">
        <title>\(esc(title))</title>
        <style>\(WebAssets.css)</style>
        </head>
        <body \(bodyAttributes)>
        \(content)
        <div id="drop"><div class="zone"><h2>松开以上传</h2><p>文件会保存到当前目录</p></div></div>
        <div id="modal"></div>
        <div id="toast"></div>
        <div id="dock"><div id="dock-list"></div></div>
        \(includeScript ? "<script>\(WebAssets.js)</script>" : "")
        </body>
        </html>
        """
    }

    private static func topbar(shareName: String, active: String) -> String {
        let filesTab = active == "files" ? "tab active" : "tab"
        let textTab = active == "text" ? "tab active" : "tab"
        return """
        <header class="topbar"><div class="topbar-inner">
        <div class="brand">
        <span class="mark">\(brandMark)</span>
        <span class="title">EZShare</span>
        <span class="sub">\(esc(shareName))</span>
        </div>
        <nav class="tabs">
        <a class="\(filesTab)" href="/">文件</a>
        <a class="\(textTab)" href="/text">文本</a>
        </nav>
        <span class="spacer"></span>
        <span class="chip"><span class="dot"></span>局域网共享中</span>
        </div></header>
        """
    }

    private static func footer() -> String {
        """
        <footer><span>EZShare</span><span class="dot"></span><span>仅同一局域网内可访问</span><span class="dot"></span><span>本地直连 · 不经云端</span></footer>
        """
    }

    // MARK: - 目录列表

    static func listing(
        relativePath: String,
        entries: [FileEntry],
        settings: ShareSettings
    ) -> String {
        let crumbs = breadcrumbs(relativePath)
        let rows = entries.map { row(for: $0, relativePath: relativePath, settings: settings) }.joined()
        let isEmpty = entries.isEmpty

        let tableBody: String
        if isEmpty {
            tableBody = """
            <div class="empty">\(emptyIcon)<h3>这个目录还是空的</h3><p>\(settings.allowUpload ? "拖入文件，或点击右上角上传" : "向共享目录放入文件后会显示在这里")</p></div>
            """
        } else {
            tableBody = """
            <table>
            <thead><tr><th>名称</th><th class="size">大小</th><th class="time">修改时间</th><th></th></tr></thead>
            <tbody>\(rows)</tbody>
            </table>
            """
        }

        let toolbarButtons: String
        if settings.allowUpload {
            toolbarButtons = """
            <button class="btn" id="btn-mkdir">\(plusIcon)新建文件夹</button>
            <button class="btn primary" id="btn-upload">\(uploadIcon)上传文件</button>
            <input type="file" id="picker" multiple hidden>
            """
        } else {
            toolbarButtons = ""
        }

        let countText = isEmpty ? "空目录" : "\(entries.count) 个项目"

        let content = """
        \(topbar(shareName: settings.shareName, active: "files"))
        <main>
        <nav class="crumbs">\(crumbs)</nav>
        <div class="panel">
        <div class="toolbar">
        <label class="search">\(searchIcon)<input id="filter" type="search" placeholder="在当前目录中筛选…" autocomplete="off"></label>
        <span class="count" id="count">\(countText)</span>
        \(toolbarButtons)
        </div>
        \(tableBody)
        </div>
        </main>
        \(footer())
        """

        let attributes = """
        data-dir="\(esc(relativePath))" data-upload="\(settings.allowUpload ? "1" : "0")" data-delete="\(settings.allowDelete ? "1" : "0")"
        """

        return shell(title: "\(settings.shareName) · EZShare", bodyAttributes: attributes, content: content, includeScript: true)
    }

    private static func breadcrumbs(_ relativePath: String) -> String {
        var parts: [String] = ["<a href=\"/\">根目录</a>"]
        guard !relativePath.isEmpty else {
            return "<span class=\"current\">根目录</span>"
        }
        var accumulated: [String] = []
        let components = relativePath.split(separator: "/").map(String.init)
        for (index, component) in components.enumerated() {
            accumulated.append(component)
            let target = accumulated.joined(separator: "/")
            if index == components.count - 1 {
                parts.append("<span class=\"sep\">/</span><span class=\"current\">\(esc(component))</span>")
            } else {
                parts.append("<span class=\"sep\">/</span><a href=\"/?path=\(target.urlEncoded)\">\(esc(component))</a>")
            }
        }
        return parts.joined()
    }

    private static func row(for entry: FileEntry, relativePath: String, settings: ShareSettings) -> String {
        let category = MimeType.category(for: entry)
        let childPath = relativePath.isEmpty ? entry.name : relativePath + "/" + entry.name
        let encoded = childPath.urlEncoded
        let href = entry.isDirectory ? "/?path=\(encoded)" : "/download?path=\(encoded)"

        var actions = ""
        if !entry.isDirectory {
            actions += "<a class=\"btn ghost icon act\" href=\"/download?path=\(encoded)\" title=\"下载\">\(downloadIcon)</a>"
        }
        if settings.allowDelete {
            actions += "<button class=\"btn ghost icon act\" data-del=\"\(encoded)\" data-isdir=\"\(entry.isDirectory ? "1" : "0")\" data-name-text=\"\(esc(entry.name))\" title=\"删除\">\(trashIcon)</button>"
        }

        let sizeCell = entry.isDirectory ? "—" : sizeText(entry.size)

        return """
        <tr data-name="\(esc(entry.name))">
        <td class="name"><a class="rowlink" href="\(href)"><span class="icon \(category.label)">\(icon(for: category))</span><span class="fname">\(esc(entry.name))</span></a></td>
        <td class="size">\(sizeCell)</td>
        <td class="time">\(dateText(entry.modified))</td>
        <td class="actions">\(actions)</td>
        </tr>
        """
    }

    // MARK: - 文本共享页

    static func textPage(snippets: [TextSnippet], settings: ShareSettings) -> String {
        let listBody: String
        if snippets.isEmpty {
            listBody = """
            <div class="empty">\(emptyIcon)<h3>还没有共享的文本</h3><p>\(settings.allowUpload ? "在上方粘贴文字后点击发送" : "共享端未开启写入，仅可查看与复制")</p></div>
            """
        } else {
            let rows = snippets.map { snippetRow($0, allowDelete: settings.allowDelete) }.joined()
            listBody = """
            <div class="snippets">\(rows)</div>
            """
        }

        let composer: String
        if settings.allowUpload {
            composer = """
            <div class="panel composer">
            <textarea id="text-input" placeholder="粘贴或输入要共享的文本，局域网内任何设备都能查看、复制…（⌘+Enter 发送）"></textarea>
            <div class="composer-foot">
            <span class="count" id="text-chars">0 字符</span>
            <span class="spacer"></span>
            <button class="btn primary" id="btn-text-send">\(uploadIcon)发送到共享</button>
            </div>
            </div>
            """
        } else {
            composer = ""
        }

        let content = """
        \(topbar(shareName: settings.shareName, active: "text"))
        <main>
        \(composer)
        <div class="panel" style="margin-top:14px">
        <div class="toolbar">
        <span class="count" id="text-count">\(snippets.count) 条文本</span>
        <span class="spacer"></span>
        <button class="btn ghost" id="btn-text-refresh">\(refreshIcon)刷新</button>
        </div>
        \(listBody)
        </div>
        </main>
        \(footer())
        """

        return shell(
            title: "文本 · \(settings.shareName) · EZShare",
            bodyAttributes: "data-text=\"1\"",
            content: content,
            includeScript: true
        )
    }

    private static func snippetRow(_ snippet: TextSnippet, allowDelete: Bool) -> String {
        var actions = "<a class=\"btn ghost icon act\" href=\"/api/text/download?id=\(snippet.id.urlEncoded)\" title=\"下载为 txt\">\(downloadIcon)</a>"
        actions += "<button class=\"btn ghost icon act\" data-textcopy=\"\(snippet.id)\" title=\"复制内容\">\(copyIcon)</button>"
        if allowDelete {
            actions += "<button class=\"btn ghost icon act\" data-textdel=\"\(snippet.id)\" title=\"删除\">\(trashIcon)</button>"
        }

        let preview = snippet.content.count > 20_000 ? String(snippet.content.prefix(20_000)) + "\n…（内容过长，仅显示前 2 万字符，下载可获取完整内容）" : snippet.content

        return """
        <div class="snippet" data-id="\(snippet.id)">
        <div class="s-head">
        <span>\(dateText(snippet.createdAt))</span>
        <span>\(sizeText(Int64(snippet.content.utf8.count)))</span>
        <span class="spacer"></span>
        \(actions)
        </div>
        <div class="s-body">\(esc(preview))</div>
        </div>
        """
    }

    // MARK: - 登录 / 错误页

    static func login(error: String?, shareName: String) -> String {
        let errorLine = error.map { "<p class=\"err\">\(esc($0))</p>" } ?? ""
        let content = """
        <div class="login-wrap"><form class="login" method="post" action="/login">
        <div class="mark">\(brandMark)</div>
        <h1>\(esc(shareName))</h1>
        <p>此共享需要访问码</p>
        <input type="password" name="code" inputmode="numeric" autocomplete="off" placeholder="••••" autofocus>
        \(errorLine)
        <button type="submit">进入共享</button>
        </form></div>
        """
        return shell(title: "输入访问码 · EZShare", bodyAttributes: "", content: content, includeScript: false)
    }

    static func errorPage(status: Int, message: String) -> String {
        let content = """
        <div class="login-wrap"><div class="login">
        <div class="mark">\(brandMark)</div>
        <h1>\(status) \(HTTPStatus.reason(status))</h1>
        <p>\(esc(message))</p>
        <a class="btn" href="/" style="width:100%;height:38px;justify-content:center;margin-top:6px">返回根目录</a>
        </div></div>
        """
        return shell(title: "出错了 · EZShare", bodyAttributes: "", content: content, includeScript: false)
    }
}
