import Foundation
import Darwin

enum NetworkInfo {
    struct Address {
        let interface: String
        let ip: String
    }

    /// 当前可用的 IPv4 局域网地址，按常见网卡优先级排序。
    static func ipv4() -> [Address] {
        var result: [Address] = []
        var listPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&listPointer) == 0, let first = listPointer else { return [] }
        defer { freeifaddrs(listPointer) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let pointer = cursor {
            let address = pointer.pointee
            cursor = address.ifa_next

            let flags = Int32(address.ifa_flags)
            guard flags & IFF_UP == IFF_UP, flags & IFF_LOOPBACK == 0 else { continue }
            guard let sockaddr = address.ifa_addr,
                  sockaddr.pointee.sa_family == UInt8(AF_INET) else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let status = getnameinfo(
                sockaddr,
                socklen_t(sockaddr.pointee.sa_len),
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard status == 0 else { continue }

            let ip = String(cString: host)
            guard !ip.isEmpty, !ip.hasPrefix("169.254."), !ip.hasPrefix("127.") else { continue }

            let name = String(cString: address.ifa_name)
            if result.contains(where: { $0.ip == ip }) { continue }
            result.append(Address(interface: name, ip: ip))
        }

        return result.sorted { rank($0.interface) < rank($1.interface) }
    }

    private static func rank(_ interface: String) -> Int {
        switch interface {
        case "en0": return 0
        case "en1": return 1
        case "en2", "en3": return 2
        default: return interface.hasPrefix("en") ? 3 : 9
        }
    }
}
