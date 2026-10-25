import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                header
                if model.localNetworkStatus == .denied {
                    permissionBanner
                }
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 14) {
                        folderCard
                        addressCard
                        Spacer(minLength: 0)
                    }
                    VStack(spacing: 14) {
                        settingsCard
                        activityCard
                    }
                    .frame(width: 356)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 26)
            .padding(.bottom, 18)
        }
        .frame(minWidth: 940, minHeight: 640)
        .onAppear {
            model.refreshAddresses()
            model.refreshTextCount()
        }
        .onReceive(refreshTimer) { _ in
            if model.isRunning {
                model.refreshAddresses()
                model.refreshTextCount()
            }
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.accent, Palette.accentAlt],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: Palette.accent.opacity(0.35), radius: 9, x: 0, y: 4)
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(y: -0.5)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("EZShare")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text("局域网文件共享 · \(model.shareName)")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            StatusPill(text: model.statusText, color: statusColor)

            PrimaryActionButton(isRunning: model.isRunning, isBusy: model.isStarting) {
                model.toggle()
            }
        }
    }

    private var statusColor: Color {
        if model.isStarting { return Palette.warning }
        guard model.isRunning else { return Palette.idle }
        if model.statusText.hasPrefix("端口") { return Palette.warning }
        return Palette.running
    }

    // MARK: - 本地网络权限

    private var permissionBanner: some View {
        HStack(spacing: 9) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.danger)

            VStack(alignment: .leading, spacing: 1) {
                Text("本地网络权限被拒绝")
                    .font(.system(size: 12, weight: .semibold))
                Text("其他设备可能无法访问共享服务。请到 系统设置 → 隐私与安全性 → 本地网络 中开启 EZShare，然后重新检测。")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            SoftButton(title: "重新检测", symbol: "arrow.clockwise") { model.probeLocalNetwork() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Palette.danger.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Palette.danger.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - 共享目录

    private var folderCard: some View {
        Card(
            "共享目录",
            systemImage: "folder",
            trailing: AnyView(
                MiniButton(symbol: "arrow.clockwise", help: "重新统计") {
                    model.refreshFolderInfo()
                }
            )
        ) {
            HStack(spacing: 12) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: model.shareDirectory.path))
                    .resizable()
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.shareName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(model.shareDirectory.path)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    SoftButton(title: "在访达中显示", symbol: "folder") { model.revealInFinder() }
                    SoftButton(title: "更改…") { model.chooseDirectory() }
                }
            }

            HStack(spacing: 7) {
                ValueChip(text: "\(model.folderItemCount) 个项目")
                ValueChip(text: "文本 \(model.textCount) 条")
                ValueChip(text: model.allowUpload ? "可上传" : "只读")
                ValueChip(text: model.requireCode ? "需访问码" : "开放访问")
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - 访问地址

    private var addressCard: some View {
        Card("访问地址", systemImage: "network") {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 6) {
                    if model.urls.isEmpty {
                        missingAddressView
                    } else {
                        ForEach(model.urls, id: \.self) { url in
                            addressRow(url)
                        }
                    }
                    if !model.isRunning {
                        Text("启动共享后，局域网内的设备即可通过以上地址访问")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                }
                .opacity(model.urls.isEmpty ? 1 : (model.isRunning ? 1 : 0.5))

                VStack(spacing: 5) {
                    if let primary = model.primaryURL {
                        QRCodeView(text: primary)
                            .frame(width: 88, height: 88)
                            .opacity(model.isRunning ? 1 : 0.4)
                        Text("扫码打开")
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var missingAddressView: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 12))
                .foregroundStyle(Palette.warning)
            Text("未检测到局域网地址")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer(minLength: 6)
            SoftButton(title: "重新检测") { model.refreshAddresses() }
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }

    private func addressRow(_ url: String) -> some View {
        HStack(spacing: 6) {
            Text(url)
                .font(.system(size: 12.5, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)
            Spacer(minLength: 6)
            MiniButton(symbol: "doc.on.doc", help: "复制地址") { model.copy(url) }
            MiniButton(symbol: "safari", help: "在浏览器中打开") { model.openInBrowser(url) }
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        )
    }

    // MARK: - 设置

    private var settingsCard: some View {
        Card("设置", systemImage: "slider.horizontal.3") {
            VStack(spacing: 11) {
                SettingRow(
                    title: "端口",
                    subtitle: model.isRunning ? "停止共享后可修改" : "被占用时自动顺延"
                ) {
                    TextField("", value: $model.port, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .frame(width: 66)
                        .disabled(model.isRunning)
                }

                Divider().opacity(0.45)

                SettingRow(title: "允许上传", subtitle: "局域网设备可写入文件") {
                    Toggle("", isOn: $model.allowUpload)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }

                SettingRow(title: "允许删除", subtitle: "删除的项目进入废纸篓") {
                    Toggle("", isOn: $model.allowDelete)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }

                SettingRow(title: "访问码", subtitle: "进入前需输入 4 位数字") {
                    Toggle("", isOn: $model.requireCode)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }

                if model.requireCode {
                    HStack(spacing: 8) {
                        TextField("访问码", text: $model.accessCode)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .frame(width: 76)
                        SoftButton(title: "随机生成", symbol: "dice") { model.randomizeCode() }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    // MARK: - 活动

    private var activityCard: some View {
        Card(
            "活动",
            systemImage: "waveform.path.ecg",
            trailing: AnyView(
                HStack(spacing: 4) {
                    ValueChip(text: "\(model.stats.requests) 次")
                    MiniButton(symbol: "trash", help: "清空记录") { model.clearLogs() }
                }
            )
        ) {
            HStack(spacing: 16) {
                statItem("下行", bytesText(model.stats.bytesOut), "arrow.down")
                statItem("上行", bytesText(model.stats.bytesIn), "arrow.up")
                Spacer(minLength: 0)
            }

            Divider().opacity(0.45)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if model.logs.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(.tertiary)
                            Text(model.isRunning ? "等待局域网设备访问" : "启动共享后这里会显示访问记录")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 26)
                    } else {
                        ForEach(Array(model.logs.enumerated()), id: \.offset) { _, log in
                            logRow(log)
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func statItem(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 8.5, weight: .bold))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
    }

    private func logRow(_ log: AccessLog) -> some View {
        HStack(spacing: 7) {
            Text(timeText(log.time))
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundStyle(.tertiary)
            Text(log.method)
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.accent)
                .frame(width: 30, alignment: .leading)
            Text(log.path)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            if log.bytes > 0 {
                Text(bytesText(log.bytes))
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            Text("\(log.status)")
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(statusColor(log.status))
        }
        .padding(.vertical, 5)
    }

    private func statusColor(_ status: Int) -> Color {
        switch status {
        case 200..<300: return Palette.running
        case 300..<400: return Palette.accent
        case 400..<500: return Palette.warning
        default: return Palette.danger
        }
    }

    private func timeText(_ date: Date) -> String {
        Self.clock.string(from: date)
    }

    private func bytesText(_ bytes: Int64) -> String {
        if bytes <= 0 { return "0 B" }
        return Self.byteFormatter.string(fromByteCount: bytes)
    }

    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()
}
