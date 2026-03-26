#!/bin/bash
# 将 Pin 编译并安装为 Pin.app 到 ~/Applications/
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/pin.swift"
BIN="$SCRIPT_DIR/pin"
APP_BUNDLE="$SCRIPT_DIR/Pin.app"
INSTALL_DIR="$HOME/Applications"

# ── 1. 编译 ──────────────────────────────────────────────
echo "正在编译..."
swiftc -O -o "$BIN" "$SRC"

# ── 2. 打包 .app bundle ──────────────────────────────────
echo "正在打包 Pin.app ..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN" "$APP_BUNDLE/Contents/MacOS/pin"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>      <string>com.zhoupeng.pin</string>
    <key>CFBundleName</key>            <string>Pin</string>
    <key>CFBundleDisplayName</key>     <string>Pin</string>
    <key>CFBundleExecutable</key>      <string>pin</string>
    <key>CFBundleVersion</key>         <string>1.0</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleIconFile</key>        <string>Pin</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHighResolutionCapable</key> <true/>
    <key>LSMinimumSystemVersion</key>  <string>12.0</string>
</dict>
</plist>
EOF

# 如果已有图标文件则一并打包
if [ -f "$SCRIPT_DIR/Pin.icns" ]; then
    cp "$SCRIPT_DIR/Pin.icns" "$APP_BUNDLE/Contents/Resources/Pin.icns"
    echo "已包含自定义图标"
fi

# ── 3. 安装到 ~/Applications/ ────────────────────────────
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/Pin.app"
cp -R "$APP_BUNDLE" "$INSTALL_DIR/"

echo ""
echo "✅ Pin.app 已安装到 $INSTALL_DIR/"
echo "   在 Spotlight 搜索 "Pin" 即可启动"
echo ""
echo "提示：如需自定义图标，运行 bash create_icon.sh <your_image.png>"
