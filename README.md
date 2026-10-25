# EZShare

macOS 原生局域网文件共享工具。Swift + SwiftUI + Network.framework 实现，零第三方依赖，App 体积约 2 MB。

## 功能

- 一键启动/停止 HTTP 共享服务，端口被占用时自动顺延
- 浏览器端：目录浏览、下载（支持 Range 断点）、拖拽/多文件上传（带进度）、新建文件夹、删除（进废纸篓，可恢复）
- 局域网地址自动检测，一键复制 / 打开，二维码供手机扫码
- 可选 4 位访问码（Cookie 会话）；上传、删除可独立开关
- 活动日志与上行/下行流量统计
- 所有配置持久化到 UserDefaults

## 构建

只需 Command Line Tools（无需安装 Xcode / SwiftPM）：

```bash
./scripts/build.sh            # 构建本机架构 build/EZShare.app
./scripts/build.sh universal  # 构建 arm64 + x86_64 通用二进制
open build/EZShare.app
```

系统要求：macOS 13+。

## 命令行模式

App 内置 headless 服务，便于脚本或 CI 验证：

```bash
./build/EZShare.app/Contents/MacOS/EZShare --headless --root ~/Downloads --port 8080 [--code 1234]
```

## 关于本机的工具链兼容性处理

本机 Command Line Tools 存在两个已知问题，构建脚本已自动处理（无需 sudo、不改系统文件）：

1. `/Library/Developer/CommandLineTools/usr/include/swift/` 中残留旧版 `module.modulemap`，与 `bridging.modulemap` 重复定义 `SwiftBridging`，导致任何 Swift 编译失败；
2. 由此引发的连锁 "SDK is not supported by the compiler" 报错。

`scripts/build.sh` 通过 `-vfsoverlay` 把残留文件映射为空文件绕过。若日后重装 CLT 后问题消失，脚本会自动检测并跳过该修复。

彻底修复本机 CLT（可选，需 sudo）：

```bash
sudo rm /Library/Developer/CommandLineTools/usr/include/swift/module.modulemap
```

## 安全说明

- 服务只读暴露共享目录内的文件；路径解析禁止 `..` 越界，删除操作仅限共享目录内部且进废纸篓
- Web 页面内置 XSS 转义；会话 Cookie 为 HttpOnly
- 仅建议在可信局域网内使用；如需防护请开启访问码

## 目录结构

```
Sources/EZShare/
├── EZShareApp.swift      # App 入口 + headless 模式
├── AppModel.swift        # 状态与配置持久化
├── Core/                 # 路径解析、网卡检测、MIME、配置存储
├── Net/                  # HTTP 服务、路由、网页（内嵌 CSS/JS，无外部资源）
└── Views/                # SwiftUI 界面
tools/make-icon.swift     # 图标生成器
scripts/build.sh          # 构建打包脚本
packaging/Info.plist
```
