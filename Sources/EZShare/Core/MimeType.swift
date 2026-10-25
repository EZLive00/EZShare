import Foundation

enum MimeType {
    private static let table: [String: String] = [
        "html": "text/html; charset=utf-8",
        "htm": "text/html; charset=utf-8",
        "css": "text/css; charset=utf-8",
        "js": "text/javascript; charset=utf-8",
        "json": "application/json; charset=utf-8",
        "txt": "text/plain; charset=utf-8",
        "md": "text/plain; charset=utf-8",
        "csv": "text/csv; charset=utf-8",
        "xml": "application/xml; charset=utf-8",
        "pdf": "application/pdf",
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "webp": "image/webp",
        "bmp": "image/bmp",
        "svg": "image/svg+xml",
        "ico": "image/x-icon",
        "heic": "image/heic",
        "mp4": "video/mp4",
        "mov": "video/quicktime",
        "mkv": "video/x-matroska",
        "webm": "video/webm",
        "avi": "video/x-msvideo",
        "mp3": "audio/mpeg",
        "m4a": "audio/mp4",
        "wav": "audio/wav",
        "flac": "audio/flac",
        "aac": "audio/aac",
        "zip": "application/zip",
        "rar": "application/vnd.rar",
        "7z": "application/x-7z-compressed",
        "tar": "application/x-tar",
        "gz": "application/gzip",
        "dmg": "application/x-apple-diskimage",
        "doc": "application/msword",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xls": "application/vnd.ms-excel",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "ppt": "application/vnd.ms-powerpoint",
        "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "epub": "application/epub+zip",
        "ttf": "font/ttf",
        "otf": "font/otf",
        "woff": "font/woff",
        "woff2": "font/woff2"
    ]

    static func of(_ url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        return table[ext] ?? "application/octet-stream"
    }

    enum Category {
        case folder, image, video, audio, archive, code, document, file

        var label: String {
            switch self {
            case .folder: return "folder"
            case .image: return "image"
            case .video: return "video"
            case .audio: return "audio"
            case .archive: return "archive"
            case .code: return "code"
            case .document: return "doc"
            case .file: return "file"
            }
        }
    }

    static func category(for entry: FileEntry) -> Category {
        if entry.isDirectory { return .folder }
        switch (entry.name as NSString).pathExtension.lowercased() {
        case "png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "heic", "tiff", "avif":
            return .image
        case "mp4", "mov", "mkv", "webm", "avi", "m4v":
            return .video
        case "mp3", "m4a", "wav", "flac", "aac", "ogg":
            return .audio
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "iso":
            return .archive
        case "swift", "js", "ts", "py", "go", "rs", "java", "c", "h", "cpp", "sh", "json", "yml", "yaml", "toml", "html", "css", "sql", "rb", "php":
            return .code
        case "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key", "txt", "md", "rtf", "epub", "csv":
            return .document
        default:
            return .file
        }
    }
}
