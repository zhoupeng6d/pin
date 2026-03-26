# Pin

一款轻量的 macOS 桌面悬浮任务清单，帮你随时找回专注力。

![macOS](https://img.shields.io/badge/macOS-12%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.7%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

[English](README_EN.md)

## 功能特点

- **始终置顶** — 悬浮于所有窗口之上，切换桌面空间和全屏应用时依然可见
- **磨砂玻璃界面** — 原生 macOS 侧边栏模糊效果，深蓝配色，简洁不干扰
- **任务管理** — 添加、勾选完成（带删除线）、一键删除
- **长按拖动** — 在窗口任意位置长按 0.1 秒即可拖动移位
- **菜单栏图标** — 左键切换显示/隐藏，右键打开选项菜单
- **开机自启** — 右键菜单一键开关，基于 Launch Agent 实现
- **数据持久化** — 任务数据本地保存，重启后不丢失
- **零依赖** — 单个 Swift 源文件，无需 Xcode 工程

## 截图

<!-- 在此处添加截图 -->

## 系统要求

- macOS 12 Monterey 及以上
- Swift 5.7+（运行 `xcode-select --install` 安装命令行工具）

## 安装

```bash
git clone https://github.com/zhoupeng6d/pin.git
cd pin
bash install.sh
```

脚本会自动编译并将 `Pin.app` 安装到 `~/Applications/`，之后在 Spotlight 搜索 **Pin** 即可启动。

## 应用图标

默认图标（深蓝背景 + 白色图钉）由脚本自动生成，与菜单栏图标风格保持一致。

重新生成并安装：

```bash
bash gen_icon.sh
```

使用自定义图标，准备一张 1024×1024 的 PNG 图片：

```bash
bash create_icon.sh 你的图片.png
bash install.sh
```

## 使用说明

| 操作 | 方式 |
|---|---|
| 添加任务 | 点击底部输入框，输入内容后按 **回车** |
| 完成任务 | 点击复选框，标题显示删除线 |
| 删除任务 | 点击右侧 **×** 按钮 |
| 移动窗口 | 在窗口任意位置长按 0.1 秒后拖动 |
| 显示/隐藏 | 左键点击菜单栏图标，或点击标题栏 **✕** |
| 开机自启 | 右键菜单栏图标 → 开机自启 |
| 退出应用 | 右键菜单栏图标 → 退出 |

## 开发

```bash
bash run.sh   # 源码有更新时自动重新编译并启动
```

## 技术实现

| 主题 | 说明 |
|---|---|
| 窗口 | 继承 `NSPanel` 并重写 `canBecomeKey = true`，解决 borderless 窗口无法接收键盘输入的问题 |
| 始终置顶 | `window.level = .floating` + `.canJoinAllSpaces` + `.stationary` + `.fullScreenAuxiliary` |
| 界面 | `NSVisualEffectView`（`.sidebar` 材质，强制 `.aqua` 外观）+ 手动 frame 布局 |
| 长按拖动 | `NSEvent` 本地事件监听，`mouseDown` 触发 0.1 秒计时器，`leftMouseDragged` 通过 `deltaX/deltaY` 更新窗口位置 |
| 数据存储 | `UserDefaults` → `~/Library/Preferences/pin.plist`（key: `pin_v1`） |
| 开机自启 | 写入 `~/Library/LaunchAgents/com.zhoupeng.pin.plist`，通过 `launchctl bootstrap` 加载 |

## 项目结构

```
pin/
├── pin.swift          # 应用全部代码，约 500 行，零外部依赖
├── run.sh             # 开发用启动脚本（按需编译）
├── install.sh         # 编译并打包为 Pin.app 安装到 ~/Applications/
├── gen_icon.sh        # 自动生成应用图标并重新安装
├── create_icon.sh     # 将自定义 PNG 转换为 Pin.icns
├── README.md
├── README_EN.md
└── LICENSE
```

## 许可证

MIT License — 详见 [LICENSE](LICENSE)
