#!/bin/bash
# 将 PNG 图片转换为 macOS App 图标 (Pin.icns)
# 用法: bash create_icon.sh <your_image.png>
#
# 要求：图片尺寸建议 1024x1024 或更大，PNG 格式
# 生成的 Pin.icns 会自动被 install.sh 打包进 Pin.app

set -e

INPUT="$1"
if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
    echo "用法: bash create_icon.sh <your_image.png>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ICONSET="$SCRIPT_DIR/Pin.iconset"
OUTPUT="$SCRIPT_DIR/Pin.icns"

echo "正在生成图标..."
mkdir -p "$ICONSET"

# 生成各尺寸
sips -z 16   16   "$INPUT" --out "$ICONSET/icon_16x16.png"      > /dev/null
sips -z 32   32   "$INPUT" --out "$ICONSET/icon_16x16@2x.png"   > /dev/null
sips -z 32   32   "$INPUT" --out "$ICONSET/icon_32x32.png"      > /dev/null
sips -z 64   64   "$INPUT" --out "$ICONSET/icon_32x32@2x.png"   > /dev/null
sips -z 128  128  "$INPUT" --out "$ICONSET/icon_128x128.png"    > /dev/null
sips -z 256  256  "$INPUT" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256  256  "$INPUT" --out "$ICONSET/icon_256x256.png"    > /dev/null
sips -z 512  512  "$INPUT" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512  512  "$INPUT" --out "$ICONSET/icon_512x512.png"    > /dev/null
sips -z 1024 1024 "$INPUT" --out "$ICONSET/icon_512x512@2x.png" > /dev/null

iconutil -c icns "$ICONSET" -o "$OUTPUT"
rm -rf "$ICONSET"

echo "✅ 生成 Pin.icns"
echo "   重新运行 bash install.sh 即可将图标打包进 Pin.app"
