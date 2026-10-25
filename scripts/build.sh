#!/bin/bash
# EZShare 构建脚本：不依赖 SwiftPM / Xcode，仅需 Command Line Tools。
# 用法:
#   ./scripts/build.sh            构建 .app（本机架构）
#   ./scripts/build.sh universal  构建通用二进制 (arm64 + x86_64)
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT_ROOT="$(pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
APP_NAME="EZShare"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
UNIVERSAL=0
[ "${1:-}" = "universal" ] && UNIVERSAL=1

SDK="$(xcrun --show-sdk-path)"
SWIFTC="$(xcrun -f swiftc)"

# ---------------------------------------------------------------------------
# 兼容性补丁：
# 1) 部分 CLT 安装在 usr/include/swift 里残留旧的 module.modulemap，与
#    bridging.modulemap 重复定义 SwiftBridging，导致编译失败。
#    用 VFS overlay 把残留文件映射为空文件，无需 sudo、不修改系统。
# 2) CLT 编译器与 SDK 版本号可能不一致（引发连锁报错），上面的修复即可解决。
# ---------------------------------------------------------------------------
VFS="$BUILD_DIR/vfs-overlay.yaml"
SWIFT_INCLUDE_DIR="$(dirname "$SWIFTC")/../include/swift"
STALE_MAP="$SWIFT_INCLUDE_DIR/module.modulemap"
BRIDGING_MAP="$SWIFT_INCLUDE_DIR/bridging.modulemap"
mkdir -p "$BUILD_DIR"
: > "$BUILD_DIR/empty.modulemap"

if [ -f "$STALE_MAP" ] && [ -f "$BRIDGING_MAP" ] \
   && grep -q "module SwiftBridging" "$STALE_MAP" \
   && grep -q "module SwiftBridging" "$BRIDGING_MAP"; then
  cat > "$VFS" <<EOF
{
  "version": 0,
  "roots": [
    {
      "name": "$STALE_MAP",
      "type": "file",
      "external-contents": "$BUILD_DIR/empty.modulemap"
    }
  ]
}
EOF
  OVERLAY_ARGS=(-vfsoverlay "$VFS")
  echo "[EZShare] 检测到重复的 SwiftBridging modulemap，已启用 VFS overlay 修复"
else
  OVERLAY_ARGS=()
fi

compile() {
  local arch="$1"
  local target
  case "$arch" in
    arm64)  target="arm64-apple-macos13.0" ;;
    x86_64) target="x86_64-apple-macos13.0" ;;
    *) echo "不支持的架构: $arch"; exit 1 ;;
  esac
  echo "[EZShare] 编译 $arch ..."
  mkdir -p "$BUILD_DIR/$arch"
  # shellcheck disable=SC2046
  "$SWIFTC" \
    -O -swift-version 5 \
    -target "$target" \
    -sdk "$SDK" \
    "${OVERLAY_ARGS[@]+"${OVERLAY_ARGS[@]}"}" \
    $(find "$PROJECT_ROOT/Sources/$APP_NAME" -name '*.swift') \
    -o "$BUILD_DIR/$arch/$APP_NAME"
}

if [ "$UNIVERSAL" = "1" ]; then
  compile arm64
  compile x86_64
  lipo -create -output "$BUILD_DIR/$APP_NAME" \
    "$BUILD_DIR/arm64/$APP_NAME" "$BUILD_DIR/x86_64/$APP_NAME"
else
  compile "$(uname -m)"
  cp "$BUILD_DIR/$(uname -m)/$APP_NAME" "$BUILD_DIR/$APP_NAME"
fi

# ---------------------------------------------------------------------------
# 打包 .app
# ---------------------------------------------------------------------------
echo "[EZShare] 打包 $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$PROJECT_ROOT/packaging/Info.plist" "$APP_DIR/Contents/Info.plist"

# 图标（生成一次后缓存）
if [ ! -f "$BUILD_DIR/Resources/AppIcon.icns" ]; then
  ICON_TOOL="$BUILD_DIR/make-icon"
  if "$SWIFTC" -O -swift-version 5 -target "$(uname -m)-apple-macos13.0" -sdk "$SDK" \
       "${OVERLAY_ARGS[@]+"${OVERLAY_ARGS[@]}"}" \
       "$PROJECT_ROOT/tools/make-icon.swift" -o "$ICON_TOOL" 2>/dev/null \
     && "$ICON_TOOL" "$BUILD_DIR/AppIcon.png" >/dev/null; then
    ICONSET="$BUILD_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for spec in "16 16" "32 16" "32 32" "64 32" "128 128" "256 128" "256 256" "512 256" "512 512" "1024 512"; do
      set -- $spec
      cp "$BUILD_DIR/AppIcon.png" "$ICONSET/icon_${1}x${2}@2x.png" 2>/dev/null || true
    done
    # 重新生成标准 iconset 命名
    rm -rf "$ICONSET"; mkdir -p "$ICONSET"
    python3 - "$BUILD_DIR/AppIcon.png" "$ICONSET" <<'PY'
import subprocess, sys
src, dst = sys.argv[1], sys.argv[2]
sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes:
    for suffix, out in ((f"{s}x{s}", s), (f"{s}x{s}@2x", s * 2)):
        if out > 1024:
            continue
        target = f"{dst}/icon_{suffix}.png"
        subprocess.run(["sips", "-z", str(out), str(out), src, "--out", target],
                       check=True, capture_output=True)
PY
    mkdir -p "$BUILD_DIR/Resources"
    iconutil -c icns "$ICONSET" -o "$BUILD_DIR/Resources/AppIcon.icns"
  else
    echo "[EZShare] 跳过图标生成（可选步骤失败）"
  fi
fi
[ -f "$BUILD_DIR/Resources/AppIcon.icns" ] && cp "$BUILD_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

# ---------------------------------------------------------------------------
# 签名（ad-hoc，保证本机可直接运行并触发本地网络权限）
# ---------------------------------------------------------------------------
codesign --force -s - "$APP_DIR" 2>/dev/null || echo "[EZShare] 警告: ad-hoc 签名失败，App 可能无法直接打开"

echo "[EZShare] 完成: $APP_DIR"
echo "运行: open \"$APP_DIR\""
