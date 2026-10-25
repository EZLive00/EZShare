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

// 白色“上传/共享”图形
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
context.setStrokeColor(white)
context.setLineWidth(58)
context.setLineCap(.round)
context.setLineJoin(.round)

// 箭杆
context.move(to: CGPoint(x: 512, y: 610))
context.addLine(to: CGPoint(x: 512, y: 252))
context.strokePath()

// 箭头
context.move(to: CGPoint(x: 372, y: 388))
context.addLine(to: CGPoint(x: 512, y: 248))
context.addLine(to: CGPoint(x: 652, y: 388))
context.strokePath()

// 托盘
let tray = CGMutablePath()
tray.move(to: CGPoint(x: 296, y: 660))
tray.addLine(to: CGPoint(x: 296, y: 736))
tray.addCurve(
    to: CGPoint(x: 396, y: 836),
    control1: CGPoint(x: 296, y: 791),
    control2: CGPoint(x: 341, y: 836)
)
tray.addLine(to: CGPoint(x: 628, y: 836))
tray.addCurve(
    to: CGPoint(x: 728, y: 736),
    control1: CGPoint(x: 683, y: 836),
    control2: CGPoint(x: 728, y: 791)
)
tray.addLine(to: CGPoint(x: 728, y: 660))
context.addPath(tray)
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
