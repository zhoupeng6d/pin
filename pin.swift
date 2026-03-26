#!/usr/bin/env swift

import Cocoa

// MARK: - Color Palette（深蓝色主题）

private let ink     = NSColor(red: 0.10, green: 0.22, blue: 0.45, alpha: 1.0)
private let inkMid  = ink.withAlphaComponent(0.50)
private let inkDim  = ink.withAlphaComponent(0.28)
private let inkFade = ink.withAlphaComponent(0.18)

// MARK: - Model

struct TodoItem: Codable {
    var id: String
    var title: String
    var completed: Bool
    init(title: String) {
        id = UUID().uuidString; self.title = title; completed = false
    }
}

class TodoStore {
    static let shared = TodoStore()
    private let key = "pin_v1"
    private(set) var items: [TodoItem] = []

    private init() { load() }
    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let v = try? JSONDecoder().decode([TodoItem].self, from: d) else { return }
        items = v
    }
    private func save() {
        if let d = try? JSONEncoder().encode(items) { UserDefaults.standard.set(d, forKey: key) }
    }
    func add(_ t: String) {
        let s = t.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        items.append(TodoItem(title: s)); save()
    }
    func remove(id: String) { items.removeAll { $0.id == id }; save() }
    func toggle(id: String) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].completed.toggle(); save()
    }
    func item(id: String) -> TodoItem? { items.first { $0.id == id } }
}

// MARK: - FloatingPanel（解决 borderless 窗口无法成为 key window 的问题）

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }   // borderless 默认 false，必须覆盖
    override var canBecomeMain: Bool { false }
}

// MARK: - Task Row

class TaskRow: NSView {
    private let store = TodoStore.shared
    private let itemId: String
    private let check = NSButton()
    private let label = NSTextField(labelWithString: "")
    private let del   = NSButton()
    var onChange: (() -> Void)?

    init(item: TodoItem) {
        itemId = item.id
        super.init(frame: .zero)
        check.setButtonType(.switch)
        check.title = ""
        check.target = self; check.action = #selector(didToggle)
        check.translatesAutoresizingMaskIntoConstraints = false

        label.font = NSFont.systemFont(ofSize: 12)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false

        del.title = "×"; del.isBordered = false
        del.font = NSFont.systemFont(ofSize: 14, weight: .light)
        del.contentTintColor = NSColor.systemRed.withAlphaComponent(0.5)
        del.target = self; del.action = #selector(didDelete)
        del.translatesAutoresizingMaskIntoConstraints = false

        render(item: item)
        [check, label, del].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            check.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            check.centerYAnchor.constraint(equalTo: centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 14),
            check.heightAnchor.constraint(equalToConstant: 14),
            label.leadingAnchor.constraint(equalTo: check.trailingAnchor, constant: 7),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(equalTo: del.leadingAnchor, constant: -4),
            del.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            del.centerYAnchor.constraint(equalTo: centerYAnchor),
            del.widthAnchor.constraint(equalToConstant: 14),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func render(item: TodoItem) {
        check.state = item.completed ? .on : .off
        if item.completed {
            label.attributedStringValue = NSAttributedString(string: item.title, attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: inkDim,
                .font: NSFont.systemFont(ofSize: 12),
            ])
        } else {
            label.attributedStringValue = NSAttributedString(string: item.title, attributes: [
                .foregroundColor: ink,
                .font: NSFont.systemFont(ofSize: 12),
            ])
        }
    }

    @objc private func didToggle() {
        store.toggle(id: itemId)
        if let item = store.item(id: itemId) { render(item: item) }
    }
    @objc private func didDelete() { onChange?() }
}

// MARK: - Drag Handle

class DragHandle: NSView {
    override func hitTest(_ p: NSPoint) -> NSView? {
        for sub in subviews.reversed() {
            if let hit = sub.hitTest(sub.convert(p, from: self)) { return hit }
        }
        return self
    }
}

// MARK: - Main View Controller

class TodoVC: NSViewController, NSTextFieldDelegate {
    private let store = TodoStore.shared

    // 亮色磨砂玻璃背景
    private lazy var bg: NSVisualEffectView = {
        let v = NSVisualEffectView()
        v.material = .sidebar
        v.blendingMode = .behindWindow
        v.state = .active
        v.appearance = NSAppearance(named: .aqua)   // 强制 light，保证亮色
        v.wantsLayer = true
        v.layer?.cornerRadius = 10
        v.layer?.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // 标题行
    private lazy var headerRow: NSView = {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "zh_CN"); fmt.dateFormat = "M月d日 E"
        let date = NSTextField(labelWithString: fmt.string(from: Date()))
        date.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        date.textColor = inkMid
        date.translatesAutoresizingMaskIntoConstraints = false

        let quit = NSButton()
        quit.title = "✕"; quit.isBordered = false
        quit.font = NSFont.systemFont(ofSize: 9)
        quit.contentTintColor = inkDim
        quit.target = self; quit.action = #selector(hideWindow)
        quit.toolTip = "隐藏"; quit.translatesAutoresizingMaskIntoConstraints = false

        let drag = DragHandle()
        drag.translatesAutoresizingMaskIntoConstraints = false

        [drag, date, quit].forEach { v.addSubview($0) }
        NSLayoutConstraint.activate([
            v.heightAnchor.constraint(equalToConstant: 28),
            drag.topAnchor.constraint(equalTo: v.topAnchor),
            drag.bottomAnchor.constraint(equalTo: v.bottomAnchor),
            drag.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            drag.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            date.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 10),
            date.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            quit.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -8),
            quit.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            quit.widthAnchor.constraint(equalToConstant: 16),
        ])
        return v
    }()

    // 任务容器（普通 NSView，高度由 taskContainerH 控制）
    private lazy var taskContainer: NSView = {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var taskContainerH: NSLayoutConstraint!

    // 输入行（常驻底部）
    private lazy var inputRow: NSView = {
        let v = NSView()
        v.translatesAutoresizingMaskIntoConstraints = false

        let icon = NSTextField(labelWithString: "＋")
        icon.font = NSFont.systemFont(ofSize: 11, weight: .light)
        icon.textColor = inkMid
        icon.translatesAutoresizingMaskIntoConstraints = false

        inputField.font = NSFont.systemFont(ofSize: 12)
        inputField.isBordered = false
        inputField.drawsBackground = false
        inputField.textColor = ink
        inputField.focusRingType = .none
        inputField.delegate = self
        inputField.placeholderAttributedString = NSAttributedString(
            string: "添加任务，回车确认",
            attributes: [.foregroundColor: inkDim, .font: NSFont.systemFont(ofSize: 12)]
        )
        inputField.translatesAutoresizingMaskIntoConstraints = false

        let line = NSView()
        line.wantsLayer = true
        line.layer?.backgroundColor = inkFade.cgColor
        line.translatesAutoresizingMaskIntoConstraints = false

        [icon, inputField, line].forEach { v.addSubview($0) }
        NSLayoutConstraint.activate([
            v.heightAnchor.constraint(equalToConstant: 28),
            icon.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 10),
            icon.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            inputField.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 4),
            inputField.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -10),
            inputField.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            inputField.heightAnchor.constraint(equalToConstant: 20),
            line.leadingAnchor.constraint(equalTo: inputField.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: inputField.trailingAnchor),
            line.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -2),
            line.heightAnchor.constraint(equalToConstant: 1),
        ])
        return v
    }()

    private let inputField = NSTextField()   // FloatingPanel.canBecomeKey=true 后普通 NSTextField 即可
    private var taskRows: [(id: String, view: TaskRow)] = []

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 60))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(bg)
        bg.addSubview(headerRow)
        bg.addSubview(taskContainer)
        bg.addSubview(inputRow)

        taskContainerH = taskContainer.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            headerRow.topAnchor.constraint(equalTo: bg.topAnchor, constant: 2),
            headerRow.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: bg.trailingAnchor),

            taskContainer.topAnchor.constraint(equalTo: headerRow.bottomAnchor),
            taskContainer.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            taskContainer.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            taskContainerH,

            inputRow.topAnchor.constraint(equalTo: taskContainer.bottomAnchor),
            inputRow.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            inputRow.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            inputRow.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -2),

            view.widthAnchor.constraint(equalToConstant: 220),
        ])

        for item in store.items { appendRow(item: item) }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        resize()
    }

    private func appendRow(item: TodoItem) {
        let row = TaskRow(item: item)
        taskContainer.addSubview(row)
        taskRows.append((id: item.id, view: row))

        let itemId = item.id
        row.onChange = { [weak self, weak row] in
            guard let self, let row else { return }
            self.store.remove(id: itemId)
            row.removeFromSuperview()
            self.taskRows.removeAll { $0.id == itemId }
            self.relayoutRows()
            self.resize()
        }
        relayoutRows()
    }

    // 手动定位所有行（macOS y 轴向上，第一行在最上方）
    private func relayoutRows() {
        let n = taskRows.count
        taskContainerH.constant = CGFloat(n) * 24
        for (i, info) in taskRows.enumerated() {
            info.view.frame = NSRect(x: 0, y: CGFloat(n - 1 - i) * 24, width: 220, height: 24)
        }
    }

    private func resize() {
        guard let window = view.window else { return }
        let h: CGFloat = 28 + CGFloat(taskRows.count) * 24 + 28 + 4
        var f = window.frame
        f.origin.y += f.height - h
        f.size.height = h
        window.setFrame(f, display: true, animate: false)
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy sel: Selector) -> Bool {
        guard sel == #selector(NSResponder.insertNewline(_:)) else { return false }
        let t = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return true }
        store.add(t); inputField.stringValue = ""
        if let last = store.items.last { appendRow(item: last) }
        resize()
        return true
    }

    @objc private func hideWindow() { view.window?.orderOut(nil) }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: FloatingPanel!
    var statusItem: NSStatusItem!

    // 长按拖动
    private var dragTimer: Timer?
    private var isDragging = false
    private var monitors: [Any] = []

    func applicationDidFinishLaunching(_ n: Notification) {
        // ── 菜单栏图标 ──────────────────────────────────────
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Pin")
            btn.image?.isTemplate = true
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
            btn.action = #selector(handleStatusClick)
            btn.target  = self
        }

        // ── 悬浮窗口 ────────────────────────────────────────
        window = FloatingPanel(
            contentRect: NSRect(x: 60, y: 400, width: 220, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = false
        window.hidesOnDeactivate = false

        let x = UserDefaults.standard.double(forKey: "todo_wx")
        let y = UserDefaults.standard.double(forKey: "todo_wy")
        if x != 0 || y != 0 { window.setFrameOrigin(NSPoint(x: x, y: y)) }

        window.contentViewController = TodoVC()
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.accessory)

        NotificationCenter.default.addObserver(
            self, selector: #selector(savePos),
            name: NSWindow.didMoveNotification, object: window
        )

        setupDragMonitors()
    }

    // MARK: - 菜单栏点击

    @objc private func handleStatusClick(_ sender: NSStatusBarButton?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: window.isVisible ? "隐藏窗口" : "显示窗口",
                                    action: #selector(toggleWindow), keyEquivalent: ""))
            menu.addItem(.separator())
            let autoTitle = isAutoLaunchEnabled ? "✓ 开机自启（点击关闭）" : "开机自启（点击开启）"
            menu.addItem(NSMenuItem(title: autoTitle,
                                    action: #selector(toggleAutoLaunch), keyEquivalent: ""))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)),
                                    keyEquivalent: "q"))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleWindow()
        }
    }

    @objc private func toggleWindow() {
        if window.isVisible { window.orderOut(nil) } else { window.makeKeyAndOrderFront(nil) }
    }

    // MARK: - 开机自启（Launch Agent）

    private let launchLabel   = "com.zhoupeng.pin"
    private var plistPath: String {
        NSHomeDirectory() + "/Library/LaunchAgents/\(launchLabel).plist"
    }
    private var isAutoLaunchEnabled: Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    @objc private func toggleAutoLaunch() {
        isAutoLaunchEnabled ? disableAutoLaunch() : enableAutoLaunch()
    }

    private func enableAutoLaunch() {
        // 取当前可执行文件的绝对路径
        let rawPath = CommandLine.arguments[0]
        let binary  = rawPath.hasPrefix("/") ? rawPath
                    : FileManager.default.currentDirectoryPath + "/" + rawPath

        let plist = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>             <string>\(launchLabel)</string>
    <key>ProgramArguments</key>  <array><string>\(binary)</string></array>
    <key>RunAtLoad</key>         <true/>
    <key>KeepAlive</key>         <false/>
</dict>
</plist>
"""
        do {
            try plist.write(toFile: plistPath, atomically: true, encoding: .utf8)
            launchctl("bootstrap", "gui/\(getuid())", plistPath)
        } catch {
            showAlert("无法写入 plist：\(error.localizedDescription)")
        }
    }

    private func disableAutoLaunch() {
        launchctl("bootout", "gui/\(getuid())/\(launchLabel)")
        try? FileManager.default.removeItem(atPath: plistPath)
    }

    @discardableResult
    private func launchctl(_ args: String...) -> Int32 {
        let t = Process()
        t.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        t.arguments = args
        try? t.run(); t.waitUntilExit()
        return t.terminationStatus
    }

    private func showAlert(_ msg: String) {
        let a = NSAlert(); a.messageText = msg; a.runModal()
    }

    @objc private func savePos() {
        UserDefaults.standard.set(Double(window.frame.origin.x), forKey: "todo_wx")
        UserDefaults.standard.set(Double(window.frame.origin.y), forKey: "todo_wy")
    }

    // MARK: - 长按拖动

    private func setupDragMonitors() {
        let down = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self, self.window.isVisible,
                  self.window.frame.contains(NSEvent.mouseLocation) else { return event }
            let t = Timer(timeInterval: 0.10, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.isDragging = true
                NSCursor.openHand.push()
            }
            RunLoop.main.add(t, forMode: .common)
            self.dragTimer = t
            return event
        }

        let drag = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            guard let self, self.isDragging else { return event }
            var o = self.window.frame.origin
            o.x += event.deltaX
            o.y -= event.deltaY
            self.window.setFrameOrigin(o)
            return nil   // 消费事件，防止视图处理拖拽
        }

        let up = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            guard let self else { return event }
            self.dragTimer?.invalidate()
            self.dragTimer = nil
            if self.isDragging {
                self.isDragging = false
                NSCursor.pop()
                self.savePos()
            }
            return event
        }

        monitors = [down, drag, up].compactMap { $0 }
    }

    // 窗口隐藏时不退出 app，保留菜单栏图标
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { false }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
