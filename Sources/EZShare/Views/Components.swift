import SwiftUI
import AppKit

enum Palette {
    static let accent = Color(red: 0.184, green: 0.420, blue: 1.000)
    static let accentAlt = Color(red: 0.071, green: 0.710, blue: 0.647)
    static let running = Color(red: 0.086, green: 0.639, blue: 0.400)
    static let warning = Color(red: 0.949, green: 0.600, blue: 0.129)
    static let danger = Color(red: 0.898, green: 0.282, blue: 0.302)
    static let idle = Color(nsColor: .secondaryLabelColor)
}

/// 品牌图形：与网页端 brandMark 完全一致的「托盘 + 上箭头」白色线条，
/// 绘制在 24×24 视口坐标系中。
struct BrandMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * rect.width / 24, y: y * rect.height / 24)
        }
        // 箭杆
        p.move(to: pt(12, 15.5))
        p.addLine(to: pt(12, 4))
        // 箭头
        p.move(to: pt(7.8, 8.2))
        p.addLine(to: pt(12, 4))
        p.addLine(to: pt(16.2, 8.2))
        // 托盘
        p.move(to: pt(4.6, 14))
        p.addLine(to: pt(4.6, 18.2))
        p.addCurve(to: pt(6.5, 20.1), control1: pt(4.6, 19.25), control2: pt(5.55, 20.1))
        p.addLine(to: pt(17.5, 20.1))
        p.addCurve(to: pt(19.4, 18.2), control1: pt(18.45, 20.1), control2: pt(19.4, 19.25))
        p.addLine(to: pt(19.4, 14))
        return p
    }
}

/// 品牌图标：渐变圆角底 + 网页端同款白色线条图形。
struct BrandMark: View {
    var size: CGFloat = 34

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Palette.accent, Palette.accentAlt],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                BrandMarkShape()
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: size * 0.044, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: size * 0.792, height: size * 0.792)
                    .aspectRatio(1, contentMode: .fit)
            )
    }
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: scheme == .dark
                    ? [Color(red: 0.063, green: 0.078, blue: 0.106), Color(red: 0.086, green: 0.102, blue: 0.129)]
                    : [Color(red: 0.965, green: 0.973, blue: 0.992), Color(red: 0.933, green: 0.949, blue: 0.976)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Palette.accent.opacity(scheme == .dark ? 0.16 : 0.10), .clear],
                center: .init(x: 0.08, y: 0.0),
                startRadius: 4,
                endRadius: 620
            )
            RadialGradient(
                colors: [Palette.accentAlt.opacity(scheme == .dark ? 0.10 : 0.07), .clear],
                center: .init(x: 1.0, y: 1.0),
                startRadius: 4,
                endRadius: 560
            )
        }
        .ignoresSafeArea()
    }
}

struct Card<Content: View>: View {
    let title: String
    let systemImage: String
    var trailing: AnyView?
    @ViewBuilder var content: () -> Content

    init(
        _ title: String,
        systemImage: String,
        trailing: AnyView? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = trailing
        self.content = content
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                if let trailing { trailing }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            shape
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.92))
                .overlay(shape.strokeBorder(Color.primary.opacity(0.055), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.055), radius: 14, x: 0, y: 7)
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.65), radius: 3)
            Text(text)
                .font(.system(size: 11.5, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4.5)
        .background(Capsule().fill(color.opacity(0.12)))
        .foregroundStyle(color)
    }
}

struct PrimaryActionButton: View {
    let isRunning: Bool
    let isBusy: Bool
    let action: () -> Void

    private var label: String {
        if isBusy { return "处理中…" }
        return isRunning ? "停止共享" : "启动共享"
    }

    private var symbol: String {
        if isBusy { return "hourglass" }
        return isRunning ? "stop.fill" : "play.fill"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 9.5, weight: .bold))
                Text(label)
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .padding(.horizontal, 15)
            .frame(height: 32)
            .background(
                Capsule().fill(
                    isRunning
                        ? AnyShapeStyle(Color.primary.opacity(0.07))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Palette.accent, Palette.accent.opacity(0.86)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
            )
            .overlay(
                Capsule().strokeBorder(Color.primary.opacity(isRunning ? 0.08 : 0.0), lineWidth: 1)
            )
            .foregroundStyle(isRunning ? Color.primary : Color.white)
            .shadow(color: isRunning ? .clear : Palette.accent.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.7 : 1)
    }
}

struct MiniButton: View {
    let symbol: String
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(help)
    }
}

struct SettingRow<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var control: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            control()
        }
    }
}

struct ValueChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.primary.opacity(0.055)))
    }
}

struct SoftButton: View {
    let title: String
    var symbol: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 9.5, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
            }
            .padding(.horizontal, 9)
            .frame(height: 25)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
