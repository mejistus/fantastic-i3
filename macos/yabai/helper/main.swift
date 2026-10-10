// aero-helper —— aero / window_switcher 用到的几个小工具（比 osascript 快得多）
//
//   aero-helper step left|right
//       模拟按 ⌃⌥← / ⌃⌥→（macOS "向左/右移动一个桌面"）。只补按用户没按着的修饰键，
//       也只松开自己按下的，所以按住 ⌃ 连按 H 也能连续切换。
//   aero-helper wait-release <shift,option,...> <秒>
//       等这些修饰键全部松开；超时仍按着则退出码为 1。
//   aero-helper native-hotkeys on|off
//       打开 / 关闭 macOS 自带的 ⌘⇥ / ⌘⇧⇥ 应用切换器和 Spotlight 的 ⌘Space（关掉后这几个键才能交给 skhd）。
//       效果持续到重新登录。yabairc 每次启动都关掉它们：⌘⇥ 和 ⌘Space 是按应用切换的列表（window_switcher --apps）。
//   aero-helper switcher [--select 窗口id] [--apps | --launchpad] [--font-size N] [--width 屏幕宽度%] [--rows N]
//       窗口切换列表。从 stdin 读 TSV：窗口id \t 桌面 \t 应用 \t 标题 \t 状态 \t pid
//       --apps：列表末尾再加上 Dock 里亮着点、但没有窗口的应用（选中时输出 app:pid:bundle id）。
//       --launchpad：应用列表（stdin 每个应用一行），和 --apps 一样加上没有窗口的应用，最后是启动台里其余的应用，
//                    按名字排序（选中时输出 app::bundle id，在后台运行的带 pid）。
//       打字直接模糊搜索，按键不经过输入法（见 PlainFieldEditor），也不切换输入法；汉字用拼音搜（全拼或首字母）。
//       ↑↓ / ⇥⇧⇥ / ⌥⇥⌥⇧⇥ / ⌘⇥⌘⇧⇥ / ⌃N⌃P 选择，回车或单击切换（输出窗口 id），Esc 关闭（退出码 1）。
//       ⌘+ / ⌘- 调整字号，⌘0 恢复默认；字号会记住。
//   aero-helper app-names <bundle id>
//       打印这个应用可能叫的名字，每行一个（运行中的显示名、CFBundleName、可执行文件名……）。yabai 规则按应用名匹配，
//       window_switcher 用它找应用固定的工作区（应用还没运行时也行，不靠 Spotlight）。
//   aero-helper default-browser
//       打印默认浏览器的 bundle id 和正在运行的进程号：com.microsoft.edgemac<TAB>123 456
//   aero-helper option-fn <命令>
//       常驻：按住 ⌥ 时按下 🌐/fn（外接键盘上 Caps Lock 改成了它）或 Caps Lock，就用 /bin/sh 执行命令。
//       skhd 绑不了修饰键，⌥ + Caps Lock 靠这个（yabairc 启动）。
//   aero-helper app-watch <aero 的路径>
//       常驻（yabairc 在登记完规则后启动）：有固定工作区的应用一被激活、而它还没有窗口，就先切到它的工作区（见"先切过去"）。
//   aero-helper date <模板>
//       按系统的语言和地区格式化当前时间（DateFormatter 模板，如 MMMdEEEHm → 10月7日 週三 13:55）。
//   aero-helper input-source
//       打印当前输入法的简称：中文 → 中，日文 → あ，韩文 → 한，英文键盘布局 → EN。
//   aero-helper ordered-out <窗口id>...
//       打印其中被应用收起来、哪个桌面上都看不到的窗口（见"收起来的窗口"）。SketchyBar 的工作区图标用。
//   aero-helper bar-stats [秒]
//       给 SketchyBar 送数据（常驻，由 sketchybarrc 启动）：每隔几秒（默认 2）推一次 CPU、内存、
//       GPU（利用率和占用的内存）、网速，磁盘每 30 秒一次；切换输入法时立刻推输入法。SketchyBar 不在了就退出。
//   aero-helper lock
//       锁屏（和 ⌃⌘Q 一样，login.framework 的 SACLockScreenImmediate）。SketchyBar 的苹果菜单用。
//   aero-helper bar-backdrop
//       SketchyBar 栏下面的底板（常驻，由 sketchybarrc 启动）：和原生菜单栏一样，是屏幕顶上那块壁纸大半径模糊、
//       略微压暗后的样子；读不到壁纸时用系统的磨砂材质。高度跟着栏走，SketchyBar 不在了就退出。
//
// 编译：aero 第一次用到时把 helper/*.swift 一起编译到 ~/.cache/fantastic-i3/aero-helper。
// SketchyBar 的数据部分（bar-stats）在 bar.swift，磨砂底板（bar-backdrop）在 backdrop.swift。

import AppKit
import Carbon
import CoreGraphics
import SQLite3

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

// MARK: - macOS 自带的 ⌘⇥ 和 ⌘Space

// 私有 API（AltTab 也是这么做的）：1 = ⌘⇥，2 = ⌘⇧⇥，64 = Spotlight（默认 ⌘Space）
@_silgen_name("CGSSetSymbolicHotKeyEnabled")
func CGSSetSymbolicHotKeyEnabled(_ hotKey: Int32, _ isEnabled: Bool) -> CGError

func setNativeHotkeys(_ enabled: Bool) {
    for hotKey: Int32 in [1, 2, 64] { _ = CGSSetSymbolicHotKeyEnabled(hotKey, enabled) }
}

// MARK: - 收起来的窗口

// 应用关掉主窗口但还在后台时（腾讯会议、微信），窗口常常只是被收起来（orderOut）：窗口服务器里还在，yabai 也还把它
// 算在原来的桌面上，只是没有 AX 引用——和 yabai 刚启动时别的桌面上还没拿到细节的真窗口一样。"摆没摆出来"才分得清。
@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> Int32
@_silgen_name("CGSWindowIsOrderedIn")
func CGSWindowIsOrderedIn(_ cid: Int32, _ wid: UInt32, _ orderedIn: UnsafeMutablePointer<DarwinBoolean>) -> CGError

func orderedOut(_ ids: [UInt32]) -> [UInt32] {
    let cid = CGSMainConnectionID()
    return ids.filter { id in
        var orderedIn: DarwinBoolean = false
        return CGSWindowIsOrderedIn(cid, id, &orderedIn) == .success && !orderedIn.boolValue
    }
}

// MARK: - 输入法

/// 当前输入法的简称：中文输入法 → 中，日文 → あ，韩文 → 한，其他（英文键盘布局等）→ 语言代码大写
func inputSourceLabel() -> String {
    let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    var language = "en"
    if let p = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages),
       let first = (Unmanaged<CFArray>.fromOpaque(p).takeUnretainedValue() as? [String])?.first {
        language = first
    }
    switch language.prefix(2) {
    case "zh": return "中"
    case "ja": return "あ"
    case "ko": return "한"
    default: return language.prefix(2).uppercased()
    }
}

// MARK: - 默认浏览器

func defaultBrowser() -> (bundle: String, pids: [pid_t])? {
    guard let url = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!),
          let bundle = Bundle(url: url)?.bundleIdentifier else { return nil }
    return (bundle, NSRunningApplication.runningApplications(withBundleIdentifier: bundle).map(\.processIdentifier))
}

// MARK: - 先切过去

/// yabai 规则里带工作区号、按应用名匹配的（Edge → 1 等）：应用名的正则和工作区号
func fixedWorkspaces() -> [(app: NSRegularExpression, space: Int)] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yabai")
    process.arguments = ["-m", "rule", "--list"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    guard (try? process.run()) != nil else { return [] }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let rules = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] ?? []
    return rules.compactMap { rule in
        guard let space = rule["space"] as? Int, space > 0, (rule["title"] as? String ?? "").isEmpty,
              let app = rule["app"] as? String, let regex = try? NSRegularExpression(pattern: app) else { return nil }
        return (regex, space)
    }
}

/// 这个进程有没有摆出来的普通大小的窗口（在哪个桌面上都算；收起来的、最小化的不算）
func hasWindows(_ pid: pid_t) -> Bool {
    let info = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    let ids = info.compactMap { window -> UInt32? in
        guard window[kCGWindowOwnerPID as String] as? pid_t == pid, window[kCGWindowLayer as String] as? Int == 0,
              let dict = window[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: dict as CFDictionary),
              bounds.width >= 100, bounds.height >= 100 else { return nil }
        return window[kCGWindowNumber as String] as? UInt32
    }
    return ids.count > orderedOut(ids).count
}

/// 从程序坞点开 Edge 时，窗口先在当前桌面上冒出来，被规则挪到工作区 1，再跟过去，看着闪一下。
/// 所以有固定工作区的应用一被激活、而它还没有窗口（刚启动，或者开着但窗口都关了，下一步就要开新窗口），
/// 就马上切到它的工作区，新窗口直接开在那里。系统的激活通知比窗口早得多（Edge 从程序坞启动时早 1.7 秒）；
/// yabai 的 application_activated 信号对还没启动完的应用要等它启动完才来，比窗口还晚，所以在这里听。
/// 规则启动时读一次，yabairc 每次都重启它
func watchAppActivation(aero: String) -> Never {
    let workspaces = fixedWorkspaces()
    NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                                      object: nil, queue: .main) { note in
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let name = app.localizedName,
              let space = workspaces.first(where: {
                  $0.app.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil })?.space,
              !hasWindows(app.processIdentifier) else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: aero)
        process.arguments = ["workspace", String(space)]
        try? process.run()
    }
    RunLoop.main.run()
    exit(0)
}

// MARK: - ⌥ + Caps Lock

// 事件回调是 C 函数，不能捕获变量，只能用全局的
var optionFnCommand = ""
var optionFnTap: CFMachPort?
var optionFnLastFlags: CGEventFlags = []

let optionFnCallback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = optionFnTap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    let flags = event.flags
    let pressed: Bool
    switch event.getIntegerValueField(.keyboardEventKeycode) {
    case 63: pressed = flags.contains(.maskSecondaryFn) && !optionFnLastFlags.contains(.maskSecondaryFn)  // 🌐/fn 按下
    case 57: pressed = true   // 没改过的 Caps Lock：每按一下只来一次（切换大小写锁定）
    default: pressed = false
    }
    optionFnLastFlags = flags
    if pressed && flags.contains(.maskAlternate) && flags.intersection([.maskCommand, .maskControl, .maskShift]).isEmpty {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", optionFnCommand]
        try? process.run()
    }
    return Unmanaged.passUnretained(event)
}

/// 主动式事件监听（只看不改）：和 skhd 一样只需要辅助功能权限（被动式的要"输入监控"权限）
func watchOptionFn(command: String) -> Never {
    optionFnCommand = command
    guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                      eventsOfInterest: CGEventMask(1 << CGEventType.flagsChanged.rawValue),
                                      callback: optionFnCallback, userInfo: nil) else {
        FileHandle.standardError.write("aero-helper option-fn：建不了事件监听（缺辅助功能权限？）\n".data(using: .utf8)!)
        exit(1)
    }
    optionFnTap = tap
    CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    CFRunLoopRun()
    exit(0)
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
                        pid: app.processIdentifier, path: nil, haystack: searchKeys("\(name) \(file)"))
        }
        .sorted { $0.app.localizedStandardCompare($1.app) == .orderedAscending }
}

/// 启动台里的应用（名字和启动台里一样），不在 bundles 里的。按名字排序。
/// 读启动台自己的数据库；读不到（比如 macOS 26 起没有启动台）就扫它收录的那几个文件夹。
func launchpadApps(excluding bundles: Set<String>) -> [Item] {
    var apps: [String: (name: String, url: URL)] = [:]
    for (title, bundle) in launchpadDatabase() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) { apps[bundle] = (title, url) }
    }
    if apps.isEmpty {
        for folder in ["/System/Applications", "/Applications", NSHomeDirectory() + "/Applications"] {
            let walker = FileManager.default.enumerator(at: URL(fileURLWithPath: folder), includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles, .skipsPackageDescendants])
            while let link = walker?.nextObject() as? URL {
                let url = link.resolvingSymlinksInPath()   // /Applications/Safari.app 是个链接
                guard url.pathExtension == "app", let bundle = Bundle(url: url)?.bundleIdentifier, apps[bundle] == nil else { continue }
                var name = FileManager.default.displayName(atPath: url.path)
                if name.hasSuffix(".app") { name.removeLast(4) }
                apps[bundle] = (name, url)
            }
        }
    }
    // 不在 Dock 里的应用（菜单栏小工具等）可能在后台开着：不标"未运行"，选中时也不用等它启动
    let running = Dictionary(NSWorkspace.shared.runningApplications.compactMap { app in
        app.bundleIdentifier.map { ($0, app.processIdentifier) } }, uniquingKeysWith: { first, _ in first })
    return apps.filter { !bundles.contains($0.key) }
        .map { bundle, app in
            let file = app.url.deletingPathExtension().lastPathComponent
            let pid = running[bundle]
            return Item(id: "app:\(pid.map(String.init) ?? ""):\(bundle)", desk: "", app: app.name, title: "",
                        state: pid == nil ? "未运行" : "", pid: pid ?? 0, path: app.url.path,
                        haystack: searchKeys("\(app.name) \(file)"))
        }
        .sorted { $0.app.localizedStandardCompare($1.app) == .orderedAscending }
}

/// 启动台的数据库（Dock 维护的 SQLite）里的应用：名字和 bundle id。删掉的应用可能还留在里面
func launchpadDatabase() -> [(title: String, bundle: String)] {
    var dir = [CChar](repeating: 0, count: Int(PATH_MAX))
    guard confstr(_CS_DARWIN_USER_DIR, &dir, dir.count) > 0 else { return [] }
    var db: OpaquePointer?
    defer { sqlite3_close(db) }
    guard sqlite3_open_v2(String(cString: dir) + "com.apple.dock.launchpad/db/db", &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK
    else { return [] }
    var query: OpaquePointer?
    defer { sqlite3_finalize(query) }
    guard sqlite3_prepare_v2(db, "SELECT title, bundleid FROM apps", -1, &query, nil) == SQLITE_OK else { return [] }
    var apps: [(String, String)] = []
    while sqlite3_step(query) == SQLITE_ROW {
        guard let title = sqlite3_column_text(query, 0), let bundle = sqlite3_column_text(query, 1) else { continue }
        apps.append((String(cString: title), String(cString: bundle)))
    }
    return apps
}

struct Item {
    let id: String
    let desk: String
    let app: String
    let title: String
    let state: String
    let pid: pid_t
    let path: String?          // 没在运行的应用：从这里取图标
    let haystack: [[Character]]   // 搜索用的几种写法（searchKeys），哪种匹配得最好算哪种
}

/// 搜索用的写法：原文；有汉字的再加上拼音，打 tianqi、tq 都能找到"天氣"。
/// 按词注音，多音字跟着词走（銀行 yinhang、音樂 yinyue）；分词器只认简体的词，所以繁体先转成简体
enum Pinyin {
    static let tokenizer = CFStringTokenizerCreate(nil, "" as CFString, CFRangeMake(0, 0), kCFStringTokenizerUnitWord,
                                                   Locale(identifier: "zh-Hans") as CFLocale)
}

func searchKeys(_ text: String) -> [[Character]] {
    let text = text.lowercased()
    guard text.unicodeScalars.contains(where: \.properties.isIdeographic) else { return [Array(text)] }
    let simplified = NSMutableString(string: text)
    CFStringTransform(simplified, nil, "Hant-Hans" as CFString, false)
    let tokenizer = Pinyin.tokenizer
    CFStringTokenizerSetString(tokenizer, simplified, CFRangeMake(0, simplified.length))
    var words: [String] = []
    while CFStringTokenizerAdvanceToNextToken(tokenizer) != [] {
        if let latin = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String {
            words.append(latin)
        }
    }
    let pinyin = NSMutableString(string: words.joined(separator: " "))
    CFStringTransform(pinyin, nil, kCFStringTransformStripDiacritics, false)
    return [Array(text), Array((pinyin as String).lowercased())]
}

/// 搜索框的字段编辑器：没有输入上下文，按键不交给输入法，直接是键盘上的字母，也不会出候选框。
/// 以前是弹出时切到系统的英文键盘布局，可搜狗这类第三方输入法的中英文是它自己内部的状态（只向系统登记了一个拼音模式），
/// 切不到"搜狗的英文"；切到系统英文的话搜狗就不再是当前输入法，它自己的快捷键（⌥⌥ 等）都用不了。这样输入法一直不动
final class PlainFieldEditor: NSTextView {
    override var inputContext: NSTextInputContext? { nil }
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

final class Switcher: NSObject, NSApplicationDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    static let defaultFontSize: CGFloat = 28
    let store = UserDefaults(suiteName: "fantastic-i3.window-switcher")!

    var all: [Item] = []
    var shown: [Item] = []
    var preselect: String?
    var fontSize: CGFloat
    var widthPercent: CGFloat = 55
    var maxRows = 12
    var includeApps = false
    var launchpad = false
    var placeholder = "切换窗口…"

    let panel = KeyPanel(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
    let search = NSTextField()
    let divider = NSBox()
    let table = NSTableView()
    let scroll = NSScrollView()
    var icons: [String: NSImage] = [:]
    var top: CGFloat?
    let fieldEditor: PlainFieldEditor = {
        let editor = PlainFieldEditor()
        editor.isFieldEditor = true
        return editor
    }()

    init(arguments: [String]) {
        var initialFont = Switcher.defaultFontSize
        var i = 0
        while i < arguments.count {
            let value = i + 1 < arguments.count ? arguments[i + 1] : ""
            switch arguments[i] {
            case "--select": preselect = value; i += 1
            case "--apps": includeApps = true
            case "--launchpad": includeApps = true; launchpad = true; placeholder = "切换应用…"
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
                            pid: pid_t(field(5)) ?? 0, path: nil,
                            haystack: searchKeys("\(field(1)) \(field(2)) \(field(3))")))
        }
        if includeApps { all += windowlessApps(excluding: Set(all.map(\.pid))) }
        if launchpad {
            all += launchpadApps(excluding: Set(all.compactMap { NSRunningApplication(processIdentifier: $0.pid)?.bundleIdentifier }))
        }
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
        panel.delegate = self   // 给搜索框换上 PlainFieldEditor

        search.isBordered = false
        search.drawsBackground = false
        search.focusRingType = .none
        search.placeholderString = placeholder
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
            // ⌥⇥ / ⌥⇧⇥ 往下 / 往上选（⌘⇥ 也一样）；不拦下来的话 ⌥⇥ 会在搜索框里打出制表符
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
            case 12, 13, 49: exit(1)                                         // ⌘Q ⌘W；⌘Space 再按一下也关掉（和 Spotlight 一样）
            default: return event
            }
            return nil
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { _ in exit(1) }

        applyFont()
        filter("")
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
        search.placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [
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
                    guard let s = item.haystack.compactMap({ fuzzyScore(term, $0) }).max() else { return nil }
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

    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        (client as? NSTextField) === search ? fieldEditor : nil
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
        icon.image = iconFor(item)
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

    func iconFor(_ item: Item) -> NSImage? {
        let key = item.path ?? String(item.pid)
        if let icon = icons[key] { return icon }
        let icon = item.path.map { NSWorkspace.shared.icon(forFile: $0) } ?? NSRunningApplication(processIdentifier: item.pid)?.icon
        icons[key] = icon
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
case "native-hotkeys":
    setNativeHotkeys(arguments.dropFirst().first == "on")
case "app-names":
    guard let bundle = arguments.dropFirst().first,
          let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) else { exit(1) }
    let info = Bundle(url: url)?.infoDictionary ?? [:]
    let names = [NSRunningApplication.runningApplications(withBundleIdentifier: bundle).first?.localizedName,
                 info["CFBundleDisplayName"] as? String, info["CFBundleName"] as? String,
                 info["CFBundleExecutable"] as? String, url.deletingPathExtension().lastPathComponent]
    var seen = Set<String>()
    for case let name? in names where !name.isEmpty && seen.insert(name).inserted { print(name) }
case "default-browser":
    guard let browser = defaultBrowser() else { exit(1) }
    print("\(browser.bundle)\t\(browser.pids.map(String.init).joined(separator: " "))")
case "option-fn":
    let command = arguments.dropFirst().joined(separator: " ")
    guard !command.isEmpty else { exit(2) }
    watchOptionFn(command: command)
case "app-watch":
    guard let aero = arguments.dropFirst().first else { exit(2) }
    watchAppActivation(aero: aero)
case "date":
    let formatter = DateFormatter()
    formatter.locale = Locale.current   // 系统设置里的语言和地区，不受 LANG 影响
    formatter.setLocalizedDateFormatFromTemplate(arguments.dropFirst().first ?? "MMMdEEEHm")
    print(formatter.string(from: Date()))
case "input-source":
    print(inputSourceLabel())
case "ordered-out":
    orderedOut(arguments.dropFirst().compactMap { UInt32($0) }).forEach { print($0) }
case "bar-stats":
    let stats = BarStats()   // 要留着强引用：定时器和通知的回调用的是 weak self
    stats.run(interval: Double(arguments.dropFirst().first ?? "") ?? 2)
case "lock":
    guard let login = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_NOW),
          let symbol = dlsym(login, "SACLockScreenImmediate") else { exit(1) }
    typealias LockScreen = @convention(c) () -> Int32
    exit(unsafeBitCast(symbol, to: LockScreen.self)() == 0 ? 0 : 1)
case "bar-backdrop":
    let backdrop = BarBackdrop()   // 同上，要留着强引用
    backdrop.run()
case "switcher":
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let switcher = Switcher(arguments: Array(arguments.dropFirst()))
    app.delegate = switcher
    app.run()
default:
    FileHandle.standardError.write("用法：aero-helper step left|right | wait-release <修饰键> <秒> | native-hotkeys on|off | switcher [选项] | app-names <bundle id> | default-browser | option-fn <命令> | app-watch <aero> | date <模板> | input-source | ordered-out <窗口id>... | bar-stats [秒] | bar-backdrop | lock\n".data(using: .utf8)!)
    exit(2)
}
