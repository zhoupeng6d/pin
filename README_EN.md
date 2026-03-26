# Pin

A lightweight macOS floating task list that keeps your focus — always visible, never in the way.

![macOS](https://img.shields.io/badge/macOS-12%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.7%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

[中文](README.md)

## Features

- **Always on top** — floats above all windows, stays visible across every Space and full-screen app
- **Frosted glass UI** — native macOS sidebar blur with a clean dark-blue-on-white design
- **Add / complete / delete tasks** — checkbox with strikethrough, one-click delete
- **Long-press to drag** — hold anywhere on the window for 0.1 s, then drag to reposition
- **Menu bar icon** — left-click to toggle show/hide; right-click for options menu
- **Auto-start on login** — one-click toggle in the right-click menu (uses Launch Agent)
- **Persistent storage** — tasks survive restarts
- **Zero dependencies** — single Swift source file, no Xcode project needed

## Screenshot

<!-- Add screenshot here -->

## Requirements

- macOS 12 Monterey or later
- Swift 5.7+ (`xcode-select --install` to get Command Line Tools)

## Install

```bash
git clone https://github.com/zhoupeng6d/pin.git
cd pin
bash install.sh
```

This compiles the source and installs `Pin.app` to `~/Applications/`. Then search **"Pin"** in Spotlight to launch.

## App Icon

The default icon (dark blue background + white pin) is auto-generated from the SF Symbol used in the menu bar, so they always match.

To regenerate and reinstall:

```bash
bash gen_icon.sh
```

To use your own custom icon instead, prepare a 1024×1024 PNG:

```bash
bash create_icon.sh your_icon.png
bash install.sh
```

## Usage

| Action | How |
|---|---|
| Add a task | Click the input field at the bottom, type, press **Return** |
| Complete a task | Click the checkbox — title gets a strikethrough |
| Delete a task | Click the **×** button on the right |
| Move the window | Long-press (0.1 s) anywhere, then drag |
| Hide / show | Left-click the menu bar icon, or click **✕** in the title bar |
| Auto-start toggle | Right-click the menu bar icon → Auto-start |
| Quit | Right-click the menu bar icon → Quit |

## Development

```bash
bash run.sh   # compile (if needed) and launch
```

## How It Works

| Topic | Detail |
|---|---|
| Window | `NSPanel` subclass with `canBecomeKey = true` — allows text input in a borderless, non-activating panel |
| Always on top | `window.level = .floating` + `.canJoinAllSpaces` + `.stationary` + `.fullScreenAuxiliary` |
| UI | `NSVisualEffectView` (`.sidebar` material, forced `.aqua`) + manual frame-based row layout |
| Long-press drag | `NSEvent` local monitors — 0.1 s timer on `mouseDown`, `deltaX/deltaY` applied on `leftMouseDragged` |
| Persistence | `UserDefaults` → `~/Library/Preferences/pin.plist` (key: `pin_v1`) |
| Auto-start | Launch Agent plist → `~/Library/LaunchAgents/com.zhoupeng.pin.plist`, loaded via `launchctl bootstrap` |

## Project Structure

```
pin/
├── pin.swift          # Entire app — ~500 lines, no dependencies
├── run.sh             # Build-if-needed + launch script
├── install.sh         # Build + package as Pin.app → ~/Applications/
├── gen_icon.sh        # Auto-generate app icon (dark blue + white pin.fill) and reinstall
├── create_icon.sh     # Convert a custom PNG → Pin.icns for the app bundle
├── README.md
├── README_EN.md
└── LICENSE
```

## License

MIT License — see [LICENSE](LICENSE) for details.
