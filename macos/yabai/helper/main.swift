// aero-helper —— aero / window_switcher 用到的几个小工具（比 osascript 快得多）
//
//   aero-helper step left|right
//       模拟按 ⌃⌥← / ⌃⌥→（macOS "向左/右移动一个桌面"）。只补按用户没按着的修饰键，
//       也只松开自己按下的，所以按住 ⌃ 连按 H 也能连续切换。
//   aero-helper wait-release <shift,option,...> <秒>
//       等这些修饰键全部松开；超时仍按着则退出码为 1。
//   aero-helper native-cmd-tab on|off
//       打开 / 关闭 macOS 自带的 ⌘⇥ / ⌘⇧⇥ 应用切换器（关掉后 ⌘⇥ 才能交给 skhd）。
//       效果持续到重新登录，所以 yabai 每次启动都执行一次 off。
//   aero-helper switcher [--select 窗口id] [--apps] [--font-size N] [--width 屏幕宽度%] [--rows N]
//       窗口切换列表。从 stdin 读 TSV：窗口id \t 桌面 \t 应用 \t 标题 \t 状态 \t pid
//       --apps：列表末尾再加上 Dock 里亮着点、但没有窗口的应用（选中时输出 app:pid:bundle id）。
//       弹出时切到系统的英文键盘布局（U.S. / ABC），打字直接模糊搜索，不经过中文输入法。
//       ↑↓ / ⇥⇧⇥ / ⌘⇥⌘⇧⇥ / ⌃N⌃P 选择，回车或单击切换（输出窗口 id），Esc 关闭（退出码 1）。
//       ⌘+ / ⌘- 调整字号，⌘0 恢复默认；字号会记住。
//
// 编译：aero 第一次用到时自动编译到 ~/.cache/fantastic-i3/aero-helper

import AppKit
import Carbon
import CoreGraphics

// MARK: - 修饰键

func modifierMask(_ names: String) -> CGEventFlags {
    var mask: CGEventFlags = []
    for name in names.split(separator: ",") {
        switch name {
        case "shift": mask.insert(.maskShift)
        case "option", "alt": mask.insert(.maskAlternate)
        case "control", "ctrl": mask.insert(.maskControl)
        case "command", "cmd": mask.insert(.maskCommand)
        default: break
        }
    }
    return mask
}

func waitRelease(_ mask: CGEventFlags, timeout: Double) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while true {
        if CGEventSource.flagsState(.combinedSessionState).intersection(mask).isEmpty { return true }
        if Date() >= deadline { return false }
        usleep(5_000)
    }
}

func step(_ key: CGKeyCode) {
    let held = CGEventSource.flagsState(.combinedSessionState)
    let source = CGEventSource(stateID: .hidSystemState)
    func post(_ code: CGKeyCode, _ down: Bool, _ flags: CGEventFlags) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down) else { return }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }
    let addControl = !held.contains(.maskControl)
    let addOption = !held.contains(.maskAlternate)
    var flags = held.intersection([.maskControl, .maskAlternate])
    if addControl { flags.insert(.maskControl); post(59, true, flags) }
    if addOption { flags.insert(.maskAlternate); post(58, true, flags) }
    post(key, true, flags.union(.maskSecondaryFn))   // 方向键带 fn 标记
    post(key, false, flags.union(.maskSecondaryFn))
    if addOption { flags.remove(.maskAlternate); post(58, false, flags) }
    if addControl { flags.remove(.maskControl); post(59, false, flags) }
}

// MARK: - macOS 自带的 ⌘⇥

// 私有 API（AltTab 也是这么做的）：1 = ⌘⇥，2 = ⌘⇧⇥
@_silgen_name("CGSSetSymbolicHotKeyEnabled")
func CGSSetSymbolicHotKeyEnabled(_ hotKey: Int32, _ isEnabled: Bool) -> CGError

func setNativeCommandTab(_ enabled: Bool) {
    for hotKey: Int32 in [1, 2] { _ = CGSSetSymbolicHotKeyEnabled(hotKey, enabled) }
}

// MARK: - 输入法

/// 切到系统的英文键盘布局：启用了哪个就用哪个（U.S.、ABC……），由系统决定
func selectEnglishInput() {
    guard let english = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue() else { return }
    TISSelectInputSource(english)
}

// MARK: - 窗口切换列表

/// Dock 里亮着点（普通应用）、但不在 pids 里的应用：窗口都关了，或者 yabai 看不到它的窗口。按名字排序。
func windowlessApps(excluding pids: Set<pid_t>) -> [Item] {
    NSWorkspace.shared.runningApplications
        .filter { $0.activationPolicy == .regular && !$0.isTerminated && !pids.contains($0.processIdentifier) }
        .compactMap { app -> Item? in
            guard let bundle = app.bundleIdentifier, let url = app.bundleURL else { return nil }
            let file = url.deletingPathExtension().lastPathComponent
            let name = app.localizedName ?? file
            return Item(id: "app:\(app.processIdentifier):\(bundle)", desk: "", app: name, title: "", state: "无窗口",
                        pid: app.processIdentifier, haystack: Array("\(name) \(file)".lowercased()))
        }
        .sorted { $0.app.localizedStandardCompare($1.app) == .orderedAscending }
}

struct Item {
    let id: String
    let desk: String
    let app: String
    let title: String
    let state: String
    let pid: pid_t
    let haystack: [Character]
}

final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class RowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        NSColor.controlAccentColor.withAlphaComponent(0.35).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 1), xRadius: 7, yRadius: 7).fill()
    }
}

/// 模糊匹配：query 的字符按顺序出现在 text 里即算匹配；连续、词首、靠前的匹配得分高
func fuzzyScore(_ query: [Character], _ text: [Character]) -> Int? {
    var qi = 0, score = 0, last = -2
    for (i, c) in text.enumerated() where qi < query.count {
        guard c == query[qi] else { continue }
        score += 10
        if i == last + 1 { score += 15 }
        if i == 0 || !(text[i - 1].isLetter || text[i - 1].isNumber) { score += 20 }
        last = i
        qi += 1
    }
    return qi == query.count ? score * 1000 - last : nil
}

final class Switcher: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    static let defaultFontSize: CGFloat = 28
    let store = UserDefaults(suiteName: "fantastic-i3.window-switcher")!

    var all: [Item] = []
    var shown: [Item] = []
    var preselect: String?
    var fontSize: CGFloat
    var widthPercent: CGFloat = 55
    var maxRows = 12
    var includeApps = false

    let panel = KeyPanel(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
    let search = NSTextField()
    let divider = NSBox()
    let table = NSTableView()
    let scroll = NSScrollView()
    var icons: [pid_t: NSImage] = [:]
    var top: CGFloat?

    init(arguments: [String]) {
        var initialFont = Switcher.defaultFontSize
        var i = 0
        while i < arguments.count {
            let value = i + 1 < arguments.count ? arguments[i + 1] : ""
            switch arguments[i] {
            case "--select": preselect = value; i += 1
            case "--apps": includeApps = true
            case "--font-size": initialFont = CGFloat(Double(value) ?? Double(initialFont)); i += 1
            case "--width": widthPercent = CGFloat(Double(value) ?? 55); i += 1
            case "--rows": maxRows = Int(value) ?? 12; i += 1
            default: break
            }
            i += 1
        }
        let saved = store.double(forKey: "fontSize")
        fontSize = saved > 0 ? CGFloat(saved) : initialFont
        super.init()

        while let line = readLine() {
            let f = line.components(separatedBy: "\t")
            guard f.count >= 3 else { continue }
            let field = { (n: Int) in n < f.count ? f[n] : "" }
            all.append(Item(id: f[0], desk: field(1), app: field(2), title: field(3), state: field(4),
                            pid: pid_t(field(5)) ?? 0,
                            haystack: Array("\(field(1)) \(field(2)) \(field(3))".lowercased())))
        }
        if includeApps { all += windowlessApps(excluding: Set(all.map(\.pid))) }
        shown = all
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !all.isEmpty else { exit(1) }

        // 圆角：用 maskImage（layer 圆角管不到窗口边缘和阴影，会出现圆角外面还有直角）
        let radius: CGFloat = 16
        let mask = NSImage(size: NSSize(width: radius * 2 + 1, height: radius * 2 + 1), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        mask.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        mask.resizingMode = .stretch

        let effect = NSVisualEffectView()
        effect.material = .popover
        effect.state = .active
        effect.blendingMode = .behindWindow
        effect.maskImage = mask

        panel.isFloatingPanel = true
        panel.level = .modalPanel
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.contentView = effect

        search.isBordered = false
        search.drawsBackground = false
        search.focusRingType = .none
        search.placeholderString = "切换窗口…"
        search.delegate = self
        search.cell?.usesSingleLineMode = true
        search.cell?.lineBreakMode = .byTruncatingTail
        effect.addSubview(search)

        divider.boxType = .separator
        effect.addSubview(divider)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("item"))
        table.addTableColumn(column)
        table.headerView = nil
        table.backgroundColor = .clear
        table.intercellSpacing = NSSize(width: 0, height: 2)
        table.selectionHighlightStyle = .regular
        table.style = .plain
        table.focusRingType = .none
        table.refusesFirstResponder = true
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.action = #selector(clicked)
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        effect.addSubview(scroll)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // ⌘⇥ / ⌘⇧⇥ 往下 / 往上选（⌥⇥ 也一样，免得在搜索框里打出制表符）
            if event.keyCode == 48 {
                let shift = event.modifierFlags.contains(.shift)
                if !event.modifierFlags.intersection([.command, .option]).isEmpty {
                    self.select(self.table.selectedRow + (shift ? -1 : 1))
                    return nil
                }
            }
            guard event.modifierFlags.contains(.command) else { return event }
            switch event.keyCode {
            case 24, 69: self.setFontSize(self.fontSize + 2)                 // ⌘= ⌘+（含小键盘）
            case 27, 78: self.setFontSize(self.fontSize - 2)                 // ⌘-
            case 29, 82: self.setFontSize(Switcher.defaultFontSize, save: false) // ⌘0 恢复默认
            case 12, 13: exit(1)                                             // ⌘Q ⌘W
            default: return event
            }
            return nil
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in exit(1) }

        applyFont()
        filter("")
        selectEnglishInput()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(search)
    }

    // 字号

    func setFontSize(_ size: CGFloat, save: Bool = true) {
        fontSize = min(max(size, 12), 72)
        if save { store.set(Double(fontSize), forKey: "fontSize") } else { store.removeObject(forKey: "fontSize") }
        applyFont()
    }

    func applyFont() {
        search.font = .systemFont(ofSize: fontSize, weight: .regular)
        search.placeholderAttributedString = NSAttributedString(string: "切换窗口…", attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .light), .foregroundColor: NSColor.tertiaryLabelColor])
        table.rowHeight = ceil(fontSize * 1.7)
        table.reloadData()
        layout()
    }

    func layout() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.visibleFrame
        let pad: CGFloat = 12
        let searchHeight = ceil(fontSize * 1.5)
        let rowHeight = table.rowHeight + table.intercellSpacing.height
        let tableHeight = CGFloat(max(1, min(shown.count, maxRows))) * rowHeight
        let width = floor(frame.width * widthPercent / 100)
        let height = pad + searchHeight + pad + tableHeight + pad / 2
        let topEdge = top ?? (frame.midY + height / 2 + frame.height * 0.1)
        top = topEdge                       // 过滤时列表变短，顶边位置保持不动
        panel.setFrame(NSRect(x: frame.midX - width / 2, y: topEdge - height, width: width, height: height), display: true)
        panel.invalidateShadow()            // 阴影跟着圆角重新计算
        search.frame = NSRect(x: pad + 6, y: height - pad - searchHeight, width: width - 2 * pad - 12, height: searchHeight)
        divider.frame = NSRect(x: pad, y: height - pad - searchHeight - pad / 2 - 1, width: width - 2 * pad, height: 1)
        scroll.frame = NSRect(x: pad / 2, y: pad / 2, width: width - pad, height: tableHeight)
        table.tableColumns.first?.width = scroll.contentSize.width
    }

    // 过滤、选择

    func filter(_ query: String) {
        let terms = query.lowercased().split(separator: " ").map(Array.init)
        if terms.isEmpty {
            shown = all
        } else {
            shown = all.enumerated().compactMap { index, item -> (Int, Int, Item)? in
                var total = 0
                for term in terms {
                    guard let s = fuzzyScore(term, item.haystack) else { return nil }
                    total += s
                }
                return (total, index, item)
            }
            .sorted { $0.0 != $1.0 ? $0.0 > $1.0 : $0.1 < $1.1 }
            .map { $0.2 }
        }
        table.reloadData()
        layout()
        let row = terms.isEmpty ? (shown.firstIndex { $0.id == preselect } ?? 0) : 0
        select(row)
    }

    func select(_ row: Int) {
        guard !shown.isEmpty else { return }
        let r = (row % shown.count + shown.count) % shown.count
        table.selectRowIndexes(IndexSet(integer: r), byExtendingSelection: false)
        table.scrollRowToVisible(r)
    }

    func confirm(_ row: Int) {
        guard shown.indices.contains(row) else { return }
        print(shown[row].id)
        fflush(stdout)
        exit(0)
    }

    @objc func clicked() { confirm(table.clickedRow) }

    func controlTextDidChange(_ obj: Notification) { filter(search.stringValue) }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.moveDown(_:)), #selector(NSResponder.insertTab(_:)): select(table.selectedRow + 1)
        case #selector(NSResponder.moveUp(_:)), #selector(NSResponder.insertBacktab(_:)): select(table.selectedRow - 1)
        case #selector(NSResponder.insertNewline(_:)): confirm(table.selectedRow)
        case #selector(NSResponder.cancelOperation(_:)): exit(1)
        default: return false
        }
        return true
    }

    // 表格

    func numberOfRows(in tableView: NSTableView) -> Int { shown.count }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? { RowView() }

    // 一行：桌面编号（右对齐的一列，淡）｜ 图标 ｜ 应用名（中等粗细）  标题（常规、次要色）  状态（更淡、更小）
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = shown[row]
        let cell = NSTableCellView()
        let rowHeight = table.rowHeight
        let width = tableColumn?.width ?? scroll.contentSize.width

        let deskFont = NSFont.monospacedDigitSystemFont(ofSize: fontSize * 0.68, weight: .medium)
        let deskWidth = ceil(("10" as NSString).size(withAttributes: [.font: deskFont]).width)
        let desk = NSTextField(labelWithString: item.desk)
        desk.font = deskFont
        desk.textColor = .tertiaryLabelColor
        desk.alignment = .right
        let deskHeight = ceil(desk.intrinsicContentSize.height)
        desk.frame = NSRect(x: 12, y: (rowHeight - deskHeight) / 2, width: deskWidth, height: deskHeight)
        cell.addSubview(desk)

        let iconSize = floor(rowHeight * 0.74)
        let icon = NSImageView(frame: NSRect(x: desk.frame.maxX + 12, y: (rowHeight - iconSize) / 2, width: iconSize, height: iconSize))
        icon.image = iconFor(item.pid)
        icon.imageScaling = .scaleProportionallyUpOrDown
        cell.addSubview(icon)

        let text = NSMutableAttributedString(string: item.app, attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium), .foregroundColor: NSColor.labelColor])
        if !item.title.isEmpty && item.title != item.app {
            text.append(NSAttributedString(string: "   \(item.title)", attributes: [
                .font: NSFont.systemFont(ofSize: fontSize * 0.9, weight: .regular), .foregroundColor: NSColor.secondaryLabelColor]))
        }
        if !item.state.isEmpty {
            text.append(NSAttributedString(string: "   \(item.state)", attributes: [
                .font: NSFont.systemFont(ofSize: fontSize * 0.68, weight: .regular), .foregroundColor: NSColor.tertiaryLabelColor]))
        }
        let label = NSTextField(labelWithAttributedString: text)
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        let x = icon.frame.maxX + 14
        let labelHeight = ceil(label.intrinsicContentSize.height)
        label.frame = NSRect(x: x, y: (rowHeight - labelHeight) / 2, width: max(0, width - x - 12), height: labelHeight)
        cell.addSubview(label)
        return cell
    }

    func iconFor(_ pid: pid_t) -> NSImage? {
        if let icon = icons[pid] { return icon }
        let icon = NSRunningApplication(processIdentifier: pid)?.icon
        icons[pid] = icon
        return icon
    }
}

// MARK: - main

let arguments = Array(CommandLine.arguments.dropFirst())
switch arguments.first {
case "step":
    step(arguments.dropFirst().first == "right" ? 124 : 123)
case "wait-release":
    let rest = Array(arguments.dropFirst())
    let mask = modifierMask(rest.first ?? "shift,option")
    let timeout = rest.count > 1 ? Double(rest[1]) ?? 1 : 1
    exit(waitRelease(mask, timeout: timeout) ? 0 : 1)
case "native-cmd-tab":
    setNativeCommandTab(arguments.dropFirst().first == "on")
case "switcher":
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let switcher = Switcher(arguments: Array(arguments.dropFirst()))
    app.delegate = switcher
    app.run()
default:
    FileHandle.standardError.write("用法：aero-helper step left|right | wait-release <修饰键> <秒> | native-cmd-tab on|off | switcher [选项]\n".data(using: .utf8)!)
    exit(2)
}
