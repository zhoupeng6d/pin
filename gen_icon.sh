#!/bin/bash
# 自动生成 Pin.app 图标（深蓝背景 + 白色 pin.fill）并重新安装
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_PNG="$SCRIPT_DIR/_pin_icon_tmp.png"

# ── 1. 用 Swift 生成 1024×1024 PNG ──────────────────────
swift - "$TMP_PNG" << 'SWIFT'
import AppKit

let outPath = CommandLine.arguments[1]
let sz: CGFloat = 1024

let img = NSImage(size: NSSize(width: sz, height: sz), flipped: false) { rect in
    let ctx = NSGraphicsContext.current!.cgContext

    // 深蓝圆角背景
    ctx.setFillColor(NSColor(red: 0.10, green: 0.22, blue: 0.45, alpha: 1.0).cgColor)
    let bg = CGPath(roundedRect: CGRect(x: 0, y: 0, width: sz, height: sz),
                    cornerWidth: 220, cornerHeight: 220, transform: nil)
    ctx.addPath(bg); ctx.fillPath()

    // 白色 pin.fill SF Symbol
    let cfg = NSImage.SymbolConfiguration(pointSize: 580, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let sym = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg) {
        let sw = sym.size.width, sh = sym.size.height
        sym.draw(in: NSRect(x: (sz - sw) / 2, y: (sz - sh) / 2, width: sw, height: sh))
    }
    return true
}

let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: outPath))
SWIFT

echo "✅ 图标 PNG 生成完成"

# ── 2. 转换为 .icns ──────────────────────────────────────
bash "$SCRIPT_DIR/create_icon.sh" "$TMP_PNG"
rm -f "$TMP_PNG"

# ── 3. 重新打包安装 ──────────────────────────────────────
bash "$SCRIPT_DIR/install.sh"
