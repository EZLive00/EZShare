// 图标生成器：swift tools/make-icon.swift <输出.png>
// 用 CoreGraphics 画一个渐变圆角方块 + 白色上传箭头，无需任何设计资源。
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let side = CGFloat(size)

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// 背景渐变
let colors = [
    CGColor(red: 0.184, green: 0.420, blue: 1.000, alpha: 1),
    CGColor(red: 0.071, green: 0.710, blue: 0.647, alpha: 1)
] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!

// 圆角方块（macOS 图标风格）
let inset: CGFloat = 28
let radius: CGFloat = 232
let bounds = CGRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
let path = CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil)
context.addPath(path)
context.clip()

context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: side),
    end: CGPoint(x: side, y: 0),
    options: []
)

// 顶部柔光
let highlight = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.28),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0)
    ] as CFArray,
    locations: [0, 1]
)!
context.drawRadialGradient(
    highlight,
    startCenter: CGPoint(x: side * 0.32, y: side * 0.82),
    startRadius: 0,
    endCenter: CGPoint(x: side * 0.42, y: side * 0.55),
    endRadius: 560,
    options: []
)

// 白色“上传/共享”图形 —— 与网页端 brandMark SVG 完全同一几何：
// viewBox 24×24，箭杆 M12 15.5V4，箭头 M7.8 8.2L12 4l4.2 4.2，
// 托盘 M4.6 14v4.2 圆角接 h11 收回，描边 1.9，圆头圆角。
// 映射：scale = 34，ox = 104，oy = 89（y 轴翻转，整体居中）。
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
context.setStrokeColor(white)
context.setLineWidth(1.9 * 34)          // ≈ 65
context.setLineCap(.round)
context.setLineJoin(.round)

func px(_ x: CGFloat) -> CGFloat { 104 + x * 34 }
func py(_ y: CGFloat) -> CGFloat { 89 + (24 - y) * 34 }

// 箭杆
context.move(to: CGPoint(x: px(12), y: py(15.5)))
context.addLine(to: CGPoint(x: px(12), y: py(4)))
context.strokePath()

// 箭头
context.move(to: CGPoint(x: px(7.8), y: py(8.2)))
context.addLine(to: CGPoint(x: px(12), y: py(4)))
context.addLine(to: CGPoint(x: px(16.2), y: py(8.2)))
context.strokePath()

// 托盘（两个圆角用三次贝塞尔近似，k ≈ 0.5523 × r）
let k: CGFloat = 0.5523 * 1.9 * 34      // ≈ 35.7
context.move(to: CGPoint(x: px(4.6), y: py(14)))
context.addLine(to: CGPoint(x: px(4.6), y: py(18.2)))
context.addCurve(
    to: CGPoint(x: px(6.5), y: py(20.1)),
    control1: CGPoint(x: px(4.6), y: py(18.2) - k),
    control2: CGPoint(x: px(6.5) - k, y: py(20.1))
)
context.addLine(to: CGPoint(x: px(17.5), y: py(20.1)))
context.addCurve(
    to: CGPoint(x: px(19.4), y: py(18.2)),
    control1: CGPoint(x: px(17.5) + k, y: py(20.1)),
    control2: CGPoint(x: px(19.4), y: py(18.2) - k)
)
context.addLine(to: CGPoint(x: px(19.4), y: py(14)))
context.strokePath()

let image = context.makeImage()!

let arguments = CommandLine.arguments
let output = arguments.count > 1 ? arguments[1] : "AppIcon.png"
let url = URL(fileURLWithPath: output) as CFURL

guard let destination = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
    fputs("无法创建输出文件: \(output)\n", stderr)
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("写入 PNG 失败\n", stderr)
    exit(1)
}
print("icon written: \(output)")
