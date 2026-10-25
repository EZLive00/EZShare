import SwiftUI
import AppKit
import CoreImage

enum QRCode {
    /// 生成黑码透明底的二维码图像，展示时铺白底以保证对比度。
    static func image(for text: String, scale: CGFloat = 10) -> NSImage? {
        let data = Data(text.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }

        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let rep = NSCIImageRep(ciImage: scaled)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
}

struct QRCodeView: View {
    let text: String
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        )
        .onAppear { image = QRCode.image(for: text) }
        .onChange(of: text) { newValue in image = QRCode.image(for: newValue) }
    }
}
