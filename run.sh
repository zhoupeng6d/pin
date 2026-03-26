#!/bin/bash
# 启动 Pin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/pin.swift"
BIN="$SCRIPT_DIR/pin"

# 如果可执行文件不存在或源码更新，重新编译
if [ ! -f "$BIN" ] || [ "$SRC" -nt "$BIN" ]; then
    echo "正在编译..."
    swiftc -O -o "$BIN" "$SRC" || exit 1
fi

# 杀掉已有实例
pkill -x pin 2>/dev/null

# 启动
"$BIN" &
echo "已启动 (PID: $!)"
