// SketchyBar 顶栏的数据（aero-helper bar-stats，由 ../../sketchybar/sketchybarrc 启动）
//
// 栏上：GPU、CPU、内存、磁盘的百分比，网速，输入法 —— 每 2 秒推一次（磁盘 30 秒一次）。
// 弹出详情：鼠标移到某项上时，plugins/hover.sh 把项名写进 /tmp/yabai-aero-$USER/bar-hover 并发 SIGUSR1，
// 这里马上、之后每 2 秒算这一项的详情，推给它弹出面板里的各行（<项>.<行>，在 sketchybarrc 里定义）。
// 只算正在看的那一项；进程排行这类比较贵的数据只在面板开着时算，而且最多 6 秒算一次。
// 面板开着时每 0.15 秒看一下鼠标位置，离开这一项和它的面板超过 0.3 秒就收起
// （SketchyBar 的 mouse.exited.global 在离开弹出面板时不触发，靠不住）。

import AppKit
import AudioToolbox
import Carbon
import CoreAudio
import CoreWLAN
import IOKit
import SystemConfiguration

// MARK: - 格式

/// 内存按 1024 进制（和活动监视器一致）
func memoryText(_ bytes: Double) -> String {
    let gib = bytes / 1_073_741_824
    return gib >= 1 ? String(format: "%.1f GB", gib) : String(format: "%.0f MB", bytes / 1_048_576)
}

/// 磁盘按 1000 进制（和访达一致）
func diskText(_ bytes: Double) -> String {
    bytes >= 100e9 ? String(format: "%.0f GB", bytes / 1e9) : String(format: "%.1f GB", bytes / 1e9)
}

/// 速度：弹出面板里用的完整写法
func speedText(_ bytesPerSecond: Double) -> String {
    switch bytesPerSecond {
    case ..<1000: return "\(Int(bytesPerSecond)) B/s"
    case ..<1_000_000: return String(format: "%.1f KB/s", bytesPerSecond / 1000)
    default: return String(format: "%.2f MB/s", bytesPerSecond / 1_000_000)
    }
}

func durationText(minutes: Int) -> String {
    minutes >= 60 ? "\(minutes / 60) 小时 \(minutes % 60) 分" : "\(minutes) 分钟"
}

/// 超过 warn / alert 变黄 / 变红（颜色和 sketchybar/colors.sh 一致）
func levelColor(_ percent: Double, warn: Double = 60, alert: Double = 85) -> String {
    percent >= alert ? red : percent >= warn ? yellow : foreground
}

/// 弹出面板的颜色（两种主题都是彩色的，和 sketchybar/colors.sh 的调色板一致）
let green = "0xff98c379", yellow = "0xffe5c07b", red = "0xffe06c75", foreground = "0xffeaeaea"

/// SketchyBar 的进程还在不在。sketchybar 命令失败不一定是它退出了：重新加载、睡眠唤醒后重建栏的那几秒里也会失败，
/// 常驻的 bar-stats / bar-backdrop 只在进程真没了的时候才退出
func sketchybarRunning() -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    process.arguments = ["-x", "sketchybar"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    guard (try? process.run()) != nil else { return true }
    process.waitUntilExit()
    return process.terminationStatus == 0
}

/// 记一行到 aero.log（和 aero log 同一个文件），常驻进程退出时留个原因
func logLine(_ text: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let line = "\(formatter.string(from: Date())) \(text)\n"
    let path = "/tmp/yabai-aero-\(NSUserName())/aero.log"
    if let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8)!)
        try? handle.close()
    }
}

func sysctlString(_ name: String) -> String? {
    var size = 0
    guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
    var buffer = [CChar](repeating: 0, count: size)
    guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
    return String(cString: buffer)
}

func sysctlInt(_ name: String) -> Int? {
    var value: Int64 = 0
    var size = MemoryLayout<Int64>.size
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
    return size == 4 ? Int(Int32(truncatingIfNeeded: value)) : Int(value)
}

// MARK: - CPU

struct CPUTicks {
    var user: UInt64 = 0, system: UInt64 = 0, idle: UInt64 = 0, nice: UInt64 = 0
    var busy: UInt64 { user + system + nice }
    var total: UInt64 { busy + idle }
}

func cpuTicks() -> CPUTicks {
    var info = host_cpu_load_info()
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
        }
    }
    guard result == KERN_SUCCESS else { return CPUTicks() }
    return CPUTicks(user: UInt64(info.cpu_ticks.0), system: UInt64(info.cpu_ticks.1),
                    idle: UInt64(info.cpu_ticks.2), nice: UInt64(info.cpu_ticks.3))
}

/// "Apple M2 · 8 核（4 性能 + 4 能效）"
func cpuTitle() -> String {
    let model = sysctlString("machdep.cpu.brand_string") ?? "CPU"
    let cores = sysctlInt("hw.ncpu") ?? 0
    if let performance = sysctlInt("hw.perflevel0.physicalcpu"), let efficiency = sysctlInt("hw.perflevel1.physicalcpu") {
        return "\(model) · \(cores) 核（\(performance) 性能 + \(efficiency) 能效）"
    }
    return "\(model) · \(cores) 核"
}

// MARK: - 进程

struct ProcessUsage {
    let name: String
    var cpu: Double      // %，可以超过 100（多核）
    var memory: Double   // 字节（常驻内存）
}

/// 按进程名合并（同名的多个进程加在一起）
func processUsage() -> [ProcessUsage] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/ps")
    process.arguments = ["-Aceo", "pcpu=,rss=,comm="]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    guard (try? process.run()) != nil else { return [] }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    var byName: [String: ProcessUsage] = [:]
    for line in String(decoding: data, as: UTF8.self).split(separator: "\n") {
        let parts = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count == 3, let cpu = Double(parts[0]), let rss = Double(parts[1]) else { continue }
        let name = String(parts[2])
        byName[name, default: ProcessUsage(name: name, cpu: 0, memory: 0)].cpu += cpu
        byName[name, default: ProcessUsage(name: name, cpu: 0, memory: 0)].memory += rss * 1024
    }
    return Array(byName.values)
}

// MARK: - 内存

struct MemoryInfo {
    var app = 0.0, wired = 0.0, compressed = 0.0, cached = 0.0
    var used: Double { app + wired + compressed }
}

/// 口径同活动监视器："已使用内存" = App 内存 + 联动内存 + 被压缩
func memoryInfo() -> MemoryInfo {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    let result = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    guard result == KERN_SUCCESS else { return MemoryInfo() }
    let page = Double(vm_kernel_page_size)
    let app = Double(stats.internal_page_count) - min(Double(stats.purgeable_count), Double(stats.internal_page_count))
    return MemoryInfo(app: app * page, wired: Double(stats.wire_count) * page,
                      compressed: Double(stats.compressor_page_count) * page,
                      cached: Double(stats.external_page_count + stats.purgeable_count) * page)
}

func swapUsage() -> (used: Double, total: Double) {
    var swap = xsw_usage()
    var size = MemoryLayout<xsw_usage>.size
    guard sysctlbyname("vm.swapusage", &swap, &size, nil, 0) == 0 else { return (0, 0) }
    return (Double(swap.xsu_used), Double(swap.xsu_total))
}

/// 内存压力：1 正常、2 警告、4 严重
func memoryPressure() -> (text: String, color: String) {
    switch sysctlInt("kern.memorystatus_vm_pressure_level") ?? 1 {
    case 4: return ("严重", red)
    case 2: return ("警告", yellow)
    default: return ("正常", green)
    }
}

// MARK: - GPU

struct GPUInfo {
    var model = "GPU", cores = 0
    var utilization = 0, renderer = 0, tiler = 0
    var inUse = 0.0, allocated = 0.0
}

/// IOAccelerator 的 PerformanceStatistics，不需要 root
func gpuInfo() -> GPUInfo? {
    var iterator: io_iterator_t = 0
    guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else { return nil }
    defer { IOObjectRelease(iterator) }
    var result: GPUInfo?
    while case let service = IOIteratorNext(iterator), service != 0 {
        defer { IOObjectRelease(service) }
        func property(_ key: String) -> Any? {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }
        guard let stats = property("PerformanceStatistics") as? [String: Any],
              let utilization = stats["Device Utilization %"] as? Int else { continue }
        var info = GPUInfo()
        info.model = property("model") as? String ?? "GPU"
        info.cores = property("gpu-core-count") as? Int ?? 0
        info.utilization = utilization
        info.renderer = stats["Renderer Utilization %"] as? Int ?? 0
        info.tiler = stats["Tiler Utilization %"] as? Int ?? 0
        info.inUse = Double(stats["In use system memory"] as? Int ?? 0)
        info.allocated = Double(stats["Alloc system memory"] as? Int ?? 0)
        result = info
    }
    return result
}

// MARK: - 磁盘

struct DiskInfo {
    var name = "磁盘", format = ""
    var total = 0.0, available = 0.0, free = 0.0   // available 含可清除空间（访达的口径），free 不含
    var used: Double { total - available }
    var purgeable: Double { max(0, available - free) }
}

func diskInfo() -> DiskInfo? {
    let keys: Set<URLResourceKey> = [.volumeLocalizedNameKey, .volumeLocalizedFormatDescriptionKey, .volumeTotalCapacityKey,
                                     .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey]
    guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys),
          let total = values.volumeTotalCapacity, total > 0,
          let available = values.volumeAvailableCapacityForImportantUsage else { return nil }
    return DiskInfo(name: values.volumeLocalizedName ?? "磁盘", format: values.volumeLocalizedFormatDescription ?? "",
                    total: Double(total), available: Double(available), free: Double(values.volumeAvailableCapacity ?? 0))
}

/// 所有块设备累计读写的字节数
func diskIOBytes() -> (read: Double, write: Double) {
    var iterator: io_iterator_t = 0
    guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator) == KERN_SUCCESS else { return (0, 0) }
    defer { IOObjectRelease(iterator) }
    var read = 0.0, write = 0.0
    while case let service = IOIteratorNext(iterator), service != 0 {
        defer { IOObjectRelease(service) }
        guard let stats = IORegistryEntryCreateCFProperty(service, "Statistics" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? [String: Any] else { continue }
        read += Double(stats["Bytes (Read)"] as? Int ?? 0)
        write += Double(stats["Bytes (Write)"] as? Int ?? 0)
    }
    return (read, write)
}

// MARK: - 网络

/// 某个网卡累计收发的字节数（32 位计数，会回绕）
func interfaceBytes(_ name: String) -> (received: UInt32, sent: UInt32)? {
    var list: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&list) == 0, let first = list else { return nil }
    defer { freeifaddrs(list) }
    for entry in sequence(first: first, next: { $0.pointee.ifa_next }) {
        let ifa = entry.pointee
        guard let addr = ifa.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK), let data = ifa.ifa_data,
              String(cString: ifa.ifa_name) == name else { continue }
        let counters = data.assumingMemoryBound(to: if_data.self).pointee
        return (counters.ifi_ibytes, counters.ifi_obytes)
    }
    return nil
}

enum InterfaceKind { case wifi, ethernet, vpn, other }

func interfaceKind(_ name: String) -> InterfaceKind {
    let wifi = (SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? []).contains {
        SCNetworkInterfaceGetInterfaceType($0) == kSCNetworkInterfaceTypeIEEE80211 && SCNetworkInterfaceGetBSDName($0) as String? == name
    }
    if wifi { return .wifi }
    if name.hasPrefix("utun") || name.hasPrefix("ppp") || name.hasPrefix("ipsec") { return .vpn }
    if name.hasPrefix("en") { return .ethernet }
    return .other
}

// MARK: - 电池

func batteryInfo() -> [String: Any]? {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    guard service != 0 else { return nil }
    defer { IOObjectRelease(service) }
    var properties: Unmanaged<CFMutableDictionary>?
    guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS else { return nil }
    return properties?.takeRetainedValue() as? [String: Any]
}

// MARK: - 声音

/// 默认输出设备的名字、音量（0-1，不支持调节时为 nil）、是否静音
func outputDevice() -> (name: String, volume: Float?, muted: Bool?)? {
    var device = AudioObjectID(0)
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                             mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr else { return nil }

    var name: Unmanaged<CFString>?
    size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    address.mSelector = kAudioObjectPropertyName
    let deviceName = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &name) == noErr
        ? (name?.takeRetainedValue() as String? ?? "输出设备") : "输出设备"

    address.mScope = kAudioDevicePropertyScopeOutput
    var volume: Float?
    address.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMainVolume
    if AudioObjectHasProperty(device, &address) {
        var value = Float32(0)
        size = UInt32(MemoryLayout<Float32>.size)
        if AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr { volume = value }
    }
    var muted: Bool?
    address.mSelector = kAudioDevicePropertyMute
    if AudioObjectHasProperty(device, &address) {
        var value = UInt32(0)
        size = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr { muted = value != 0 }
    }
    return (deviceName, volume, muted)
}

// MARK: - 输入法

/// 已启用的键盘输入法（名字、是否当前）
func inputSources() -> [(name: String, current: Bool)] {
    func string(_ source: TISInputSource, _ key: CFString) -> String {
        guard let p = TISGetInputSourceProperty(source, key) else { return "" }
        return Unmanaged<CFString>.fromOpaque(p).takeUnretainedValue() as String
    }
    let current = string(TISCopyCurrentKeyboardInputSource().takeRetainedValue(), kTISPropertyInputSourceID)
    let filter = [kTISPropertyInputSourceIsSelectCapable as String: true,
                  kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String] as CFDictionary
    let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] ?? []
    return list.map { (string($0, kTISPropertyLocalizedName), string($0, kTISPropertyInputSourceID) == current) }
}

// MARK: - 日期

/// 农历："丙午马年 八月廿七"（闰月加"闰"）
func lunarDate(_ date: Date) -> String {
    let calendar = Calendar(identifier: .chinese)
    let c = calendar.dateComponents(in: TimeZone.current, from: date)
    guard let year = c.year, let month = c.month, let day = c.day else { return "" }
    let stems = Array("甲乙丙丁戊己庚辛壬癸"), branches = Array("子丑寅卯辰巳午未申酉戌亥"), animals = Array("鼠牛虎兔龙蛇马羊猴鸡狗猪")
    let months = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
    let digits = Array("一二三四五六七八九十")
    let dayText: String
    switch day {
    case 1...10: dayText = "初" + String(digits[day - 1])
    case 11...19: dayText = "十" + String(digits[day - 11])
    case 20: dayText = "二十"
    case 21...29: dayText = "廿" + String(digits[day - 21])
    default: dayText = "三十"
    }
    return "\(stems[(year - 1) % 10])\(branches[(year - 1) % 12])\(animals[(year - 1) % 12])年 "
        + "\(c.isLeapMonth == true ? "闰" : "")\(months[month - 1])月\(dayText)"
}

func formatted(_ date: Date, _ template: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.setLocalizedDateFormatFromTemplate(template)
    return formatter.string(from: date)
}

// MARK: - 推送

final class BarStats {
    let sketchybar = "/opt/homebrew/bin/sketchybar"
    let hoverFile = "/tmp/yabai-aero-\(NSUserName())/bar-hover"
    /// CPU、GPU 最近的利用率（0–1），最多 historyLength 个点 = 弹出面板里曲线的宽度（sketchybarrc：POPUP_WIDTH - 28）。
    /// 重新加载 SketchyBar 时这个进程会被停掉、曲线也会清零：停掉前存进 historyFile，新进程启动时读回来补上
    var history: [String: [Double]] = ["cpu": [], "gpu": []]
    let historyLength = 272
    let historyFile = "/tmp/yabai-aero-\(NSUserName())/bar-history.json"
    var termSource: DispatchSourceSignal?
    let memoryTotal = Double(ProcessInfo.processInfo.physicalMemory)
    let store = SCDynamicStoreCreate(nil, "aero-helper" as CFString, nil, nil)
    var signalSource: DispatchSourceSignal?
    var ticks = 0

    // 开着的弹出面板：哪一项、面板加这一项占的区域（屏幕坐标，左上角为原点）、鼠标从什么时候起在外面
    var popup: (item: String, area: CGRect, outsideSince: Date?)?
    var popupTimer: Timer?
    var processCache: (time: Date, list: [ProcessUsage])?

    // 上一次采样，用来算这 2 秒的变化
    var lastCPU = cpuTicks()
    var lastNet: (name: String, bytes: (received: UInt32, sent: UInt32), time: Date)?
    var lastDiskIO = (bytes: diskIOBytes(), time: Date())

    // 最近一次算出来的值，弹出面板直接用
    var cpu = (user: 0.0, system: 0.0, idle: 100.0)
    var net = (name: "", kind: InterfaceKind.other, down: 0.0, up: 0.0)
    var diskIO = (read: 0.0, write: 0.0)

    // 栏上的图标（Maple Mono NF 里的 Nerd Font 字形）
    let wifiIcon = "\u{F05A9}", ethernetIcon = "\u{F0200}", vpnIcon = "\u{F0582}", otherIcon = "\u{F059F}", offlineIcon = "\u{F05AA}"
    /// 栏上属于同一项的几块：网速拆成了 net（类型图标）、net.rx（↓）、net.tx（↑），箭头才能单独上色。
    /// 鼠标在这几块之间移动时面板不收
    let barParts = ["net": ["net.rx", "net.tx"]]

    func run(interval: TimeInterval) {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil, queue: .main
        ) { [weak self] _ in self?.inputChanged() }
        // hover.sh 打开弹出面板时发 SIGUSR1：马上推那一项的详情
        signal(SIGUSR1, SIG_IGN)
        signalSource = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        signalSource?.setEventHandler { [weak self] in
            guard let self, let item = self.hovered() else { return }
            self.send(self.details(item))
            self.watchPopup(item)
        }
        signalSource?.resume()
        // 被停掉（sketchybarrc 重新加载时 pkill）之前把曲线的历史存下来
        signal(SIGTERM, SIG_IGN)
        termSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        termSource?.setEventHandler { [weak self] in self?.quit() }
        termSource?.resume()
        restoreHistory()

        sendStatic()
        inputChanged()
        // 第一次稍等一下再算：CPU 用的是两次采样的差，间隔太短数字会乱跳
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in self?.tick() }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.run()
    }

    /// 调一次 sketchybar 命令；SketchyBar 不在了（命令失败）就退出
    func send(_ arguments: [String]) {
        guard !arguments.isEmpty else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sketchybar)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { quitIfGone(); return }
        process.waitUntilExit()
        if process.terminationStatus != 0 { quitIfGone() }
    }

    /// 命令失败了：SketchyBar 真不在了才退出，只是一时忙（重新加载、睡眠唤醒）就跳过这一次
    func quitIfGone() {
        if !sketchybarRunning() {
            logLine("bar-stats 退出：SketchyBar 不在了")
            quit()
        }
    }

    func quit() -> Never {
        if let data = try? JSONSerialization.data(withJSONObject: history) {
            try? data.write(to: URL(fileURLWithPath: historyFile))
        }
        exit(0)
    }

    /// 读回上一个进程存的历史（2 分钟以内的才算），补到栏上的曲线里（按时间顺序推，栏上的曲线只留最后那几个点）
    func restoreHistory() {
        let url = URL(fileURLWithPath: historyFile)
        guard let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
              Date().timeIntervalSince(modified) < 120,
              let data = try? Data(contentsOf: url), let saved = try? JSONSerialization.jsonObject(with: data) as? [String: [Double]]
        else { return }
        var args: [String] = []
        for item in ["cpu", "gpu"] {
            let values = Array((saved[item] ?? []).suffix(historyLength))
            history[item] = values
            if !values.isEmpty { args += ["--push", item] + values.map { String(format: "%.3f", $0) } }
        }
        send(args)
    }

    func record(_ item: String, _ value: Double) {
        history[item, default: []].append(value)
        if history[item]!.count > historyLength { history[item]!.removeFirst(history[item]!.count - historyLength) }
    }

    /// 弹出面板里的曲线：SketchyBar 画弹出面板里的曲线时最新的点在最左边，和栏上（最新在右）反着。
    /// 所以面板开着时每次把整段历史重推一遍，顺序排成画出来最新在右：先推最旧的一个，再从最新推到第二旧的
    /// （曲线是个环形缓冲区，推满一圈后第 i 个推进去的点画在第 i 个位置，第 0 个在最左边，其余从第 width-1 个往右排）。
    /// 不够一圈的用 0 补在最旧那头
    func historyPush(_ item: String) -> [String] {
        let values = history[item] ?? []
        let full = [Double](repeating: 0, count: max(0, historyLength - values.count)) + values.suffix(historyLength)
        let order = [full[0]] + full[1...].reversed()
        return ["--push", "\(item).history"] + order.map { String(format: "%.3f", $0) }
    }

    func hovered() -> String? {
        let name = (try? String(contentsOfFile: hoverFile, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
        return name?.isEmpty == false ? name : nil
    }

    /// 不会变的：各弹出面板的标题
    func sendStatic() {
        var args = ["--set", "cpu.title", "label=\(cpuTitle())",
                    "--set", "mem.title", "label=内存 · \(memoryText(memoryTotal))"]
        if let gpu = gpuInfo() {
            args += ["--set", "gpu.title", "label=\(gpu.model) · \(gpu.cores) 核 GPU"]
        }
        if let disk = diskInfo() {
            args += ["--set", "disk.title", "label=\(disk.name)\(disk.format.isEmpty ? "" : " · \(disk.format)")"]
        }
        send(args)
    }

    func inputChanged() {
        var args = ["--set", "input", "label=\(inputSourceLabel())"]
        if hovered() == "input" { args += details("input") }
        send(args)
    }

    func tick() {
        var args: [String] = []

        // CPU：栏上百分比和曲线，弹出面板里的曲线
        let ticksNow = cpuTicks()
        let total = Double(ticksNow.total &- lastCPU.total)
        if total > 0 {
            cpu = (Double(ticksNow.user &- lastCPU.user + ticksNow.nice &- lastCPU.nice) / total * 100,
                   Double(ticksNow.system &- lastCPU.system) / total * 100,
                   Double(ticksNow.idle &- lastCPU.idle) / total * 100)
        }
        lastCPU = ticksNow
        let cpuPercent = 100 - cpu.idle
        record("cpu", cpuPercent / 100)
        args += ["--push", "cpu", String(format: "%.3f", cpuPercent / 100), "--set", "cpu", percentLabel(cpuPercent)]

        let memPercent = memoryInfo().used / memoryTotal * 100
        args += ["--set", "mem", percentLabel(memPercent)]

        if let gpu = gpuInfo() {
            record("gpu", Double(gpu.utilization) / 100)
            args += ["--set", "gpu", percentLabel(Double(gpu.utilization)),
                     "--push", "gpu", String(format: "%.3f", Double(gpu.utilization) / 100)]
        }

        args += network()

        // 磁盘读写速度（弹出面板用），已用百分比 30 秒一次
        let io = diskIOBytes(), now = Date()
        let seconds = max(now.timeIntervalSince(lastDiskIO.time), 0.1)
        diskIO = (max(0, io.read - lastDiskIO.bytes.read) / seconds, max(0, io.write - lastDiskIO.bytes.write) / seconds)
        lastDiskIO = (io, now)
        if ticks % 15 == 0, let disk = diskInfo() {
            let used = disk.used / disk.total * 100
            args += ["--set", "disk", percentLabel(used)]
        }
        ticks += 1

        if let item = hovered() { args += details(item) }
        send(args)
    }

    /// 栏上的百分比。不补空格：SketchyBar 按字形轮廓算文字宽度，开头的空格不算宽度却照样画出来，
    /// 文字会往右挤进下一项。宽度由 sketchybarrc 里固定的 label.width 管（左对齐，数字贴着图标）。
    /// 满载写 "100" 不带 %：和 "99%" 一样宽，固定宽度只要容下两位数，平时图标和数字之间不留空
    func percentLabel(_ percent: Double) -> String {
        let value = Int(min(max(percent, 0), 100).rounded())
        return value == 100 ? "label=100" : "label=\(value)%"
    }

    /// 栏上的网络：主网卡（默认路由所在的）类型图标和上下行速度，分别推给 net / net.rx / net.tx
    func network() -> [String] {
        guard let store, let global = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
              let name = global["PrimaryInterface"] as? String, let bytes = interfaceBytes(name) else {
            lastNet = nil
            net = ("", .other, 0, 0)
            return ["--set", "net", "icon=\(offlineIcon)", "--set", "net.rx", "icon.drawing=off", "label=离线",
                    "--set", "net.tx", "drawing=off"]
        }
        let now = Date()
        var down = 0.0, up = 0.0
        if let last = lastNet, last.name == name {
            let seconds = max(now.timeIntervalSince(last.time), 0.1)
            down = Double(bytes.received &- last.bytes.received) / seconds
            up = Double(bytes.sent &- last.bytes.sent) / seconds
        }
        lastNet = (name, bytes, now)
        let kind = interfaceKind(name)
        net = (name, kind, down, up)
        let icon = [InterfaceKind.wifi: wifiIcon, .ethernet: ethernetIcon, .vpn: vpnIcon][kind] ?? otherIcon
        return ["--set", "net", "icon=\(icon)", "--set", "net.rx", "icon.drawing=on", "label=\(rate(down))",
                "--set", "net.tx", "drawing=on", "label=\(rate(up))"]
    }

    /// 栏上的速度，最多 4 个字符："999B" "9.9K" "456K" "1.2M" "12M"（字符少，固定宽度就窄，数字短时空出来的也少）。
    /// 不补空格：宽度由 sketchybarrc 里固定的 label.width 管（左对齐）
    func rate(_ bytesPerSecond: Double) -> String {
        switch bytesPerSecond {
        case ..<1000: return "\(Int(bytesPerSecond))B"
        case ..<9_950: return String(format: "%.1fK", bytesPerSecond / 1000)
        case ..<999_500: return "\(Int((bytesPerSecond / 1000).rounded()))K"
        case ..<9_950_000: return String(format: "%.1fM", bytesPerSecond / 1_000_000)
        default: return "\(Int((bytesPerSecond / 1_000_000).rounded()))M"
        }
    }

    // MARK: 弹出面板

    /// 进程列表：只在 CPU / 内存面板开着时用，最多 6 秒算一次
    func processes() -> [ProcessUsage] {
        if let cache = processCache, Date().timeIntervalSince(cache.time) < 6 { return cache.list }
        let list = processUsage()
        processCache = (Date(), list)
        return list
    }

    /// 读 sketchybar --query 的 JSON
    func query(_ name: String) -> [String: Any]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sketchybar)
        process.arguments = ["--query", name]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// 某一项（或面板里某一行）在屏幕上的位置；没画出来时是 nil
    /// 接了几块屏时栏上的项每块屏各有一个：给了 near 就挑离它最近的那个（和弹出面板在同一块屏上的）。
    /// 以前随便取一个，取到另一块屏上的，和面板合起来的区域横跨两块屏，鼠标总在里面，面板就一直不收
    func frame(_ name: String, near: CGRect? = nil) -> CGRect? {
        guard let rects = query(name)?["bounding_rects"] as? [String: Any] else { return nil }
        let all = rects.values.compactMap { value -> CGRect? in
            guard let rect = value as? [String: Any], let origin = rect["origin"] as? [Double], let size = rect["size"] as? [Double],
                  origin.count == 2, size.count == 2, origin[0] > -9000 else { return nil }
            return CGRect(x: origin[0], y: origin[1], width: size[0], height: size[1])
        }
        guard let near else { return all.first }
        let distance = { (r: CGRect) in hypot(r.midX - near.midX, r.midY - near.midY) }
        return all.min { distance($0) < distance($1) }
    }

    /// 面板打开后：量出这一项（连同 barParts 里的几块）加面板（标题行到最后的提示行）占的区域，开始盯鼠标。
    /// 面板还没画出来（量不到）就过一会儿再量，最多试 5 次
    func watchPopup(_ item: String, attempt: Int = 1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self, self.hovered() == item else { return }
            // 面板只在一块屏上：先量面板，再挑和它同一块屏上的那一项
            guard let top = self.frame("\(item).title"), let bottom = self.frame("\(item).hint", near: top),
                  let bar = self.frame(item, near: top) else {
                if attempt < 5 { self.watchPopup(item, attempt: attempt + 1) }
                return
            }
            let parts = (self.barParts[item] ?? []).compactMap { self.frame($0, near: top) }
            let area = parts.reduce(bar.union(top).union(bottom)) { $0.union($1) }
            self.popup = (item, area.insetBy(dx: -10, dy: -10), nil)
            if self.popupTimer == nil {
                self.popupTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in self?.checkPointer() }
            }
        }
    }

    /// 鼠标离开这一项和它的面板超过 0.3 秒就收起面板
    func checkPointer() {
        guard let current = popup, hovered() == current.item else {
            popup = nil
            popupTimer?.invalidate()
            popupTimer = nil
            return
        }
        let location = CGEvent(source: nil)?.location ?? .zero
        if current.area.contains(location) {
            popup?.outsideSince = nil
        } else if let since = current.outsideSince {
            if Date().timeIntervalSince(since) >= 0.3 {
                send(["--set", current.item, "popup.drawing=off"])
                try? FileManager.default.removeItem(atPath: hoverFile)
                popup = nil
            }
        } else {
            popup?.outsideSince = Date()
        }
    }

    /// 某一项弹出面板各行的内容（sketchybar --set 参数）
    func details(_ item: String) -> [String] {
        var args: [String] = []
        func row(_ name: String, _ value: String, color: String = foreground) {
            args += ["--set", "\(item).\(name)", "label=\(value)", "label.color=\(color)"]
        }
        func hide(_ name: String, _ hidden: Bool) {
            args += ["--set", "\(item).\(name)", "drawing=\(hidden ? "off" : "on")"]
        }
        /// 进程排行的五行：图标位置放进程名，值放用量
        func top(_ processes: [ProcessUsage], _ value: (ProcessUsage) -> String) {
            for i in 0..<5 {
                if i < processes.count {
                    let name = processes[i].name.count > 20 ? String(processes[i].name.prefix(19)) + "…" : processes[i].name
                    args += ["--set", "\(item).top.\(i)", "drawing=on", "icon=\(name)", "label=\(value(processes[i]))"]
                } else {
                    hide("top.\(i)", true)
                }
            }
        }

        switch item {
        case "gpu":
            args += historyPush("gpu")
            guard let gpu = gpuInfo() else { break }
            row("util", "\(gpu.utilization)%", color: levelColor(Double(gpu.utilization)))
            row("render", "\(gpu.renderer)%")
            row("tiler", "\(gpu.tiler)%")
            row("mem", memoryText(gpu.inUse))
            row("alloc", memoryText(gpu.allocated))

        case "cpu":
            args += historyPush("cpu")
            row("user", String(format: "%.1f%%", cpu.user))
            row("system", String(format: "%.1f%%", cpu.system))
            row("idle", String(format: "%.1f%%", cpu.idle))
            var load = [Double](repeating: 0, count: 3)
            getloadavg(&load, 3)
            row("load", String(format: "%.2f  %.2f  %.2f", load[0], load[1], load[2]))
            row("uptime", durationText(minutes: Int(ProcessInfo.processInfo.systemUptime / 60)))
            top(processes().sorted { $0.cpu > $1.cpu }) { String(format: "%.1f%%", $0.cpu) }

        case "mem":
            let memory = memoryInfo(), swap = swapUsage(), pressure = memoryPressure()
            let percent = memory.used / memoryTotal * 100
            args += ["--set", "mem.bar", "slider.percentage=\(Int(percent))",
                     "slider.highlight_color=\(percent >= 90 ? red : percent >= 75 ? yellow : green)"]
            row("used", String(format: "%@（%.0f%%）", memoryText(memory.used), percent), color: levelColor(percent, warn: 75, alert: 90))
            row("app", memoryText(memory.app))
            row("wired", memoryText(memory.wired))
            row("compressed", memoryText(memory.compressed))
            row("cached", memoryText(memory.cached))
            row("swap", swap.total > 0 ? "\(memoryText(swap.used)) / \(memoryText(swap.total))" : "未使用")
            row("pressure", pressure.text, color: pressure.color)
            top(processes().sorted { $0.memory > $1.memory }) { memoryText($0.memory) }

        case "disk":
            guard let disk = diskInfo() else { break }
            let percent = disk.used / disk.total * 100
            args += ["--set", "disk.bar", "slider.percentage=\(Int(percent))",
                     "slider.highlight_color=\(percent >= 90 ? red : percent >= 80 ? yellow : green)"]
            row("used", String(format: "%@（%.0f%%）", diskText(disk.used), percent), color: levelColor(percent, warn: 80, alert: 90))
            row("free", diskText(disk.available))
            row("purgeable", diskText(disk.purgeable))
            row("total", diskText(disk.total))
            row("read", speedText(diskIO.read))
            row("write", speedText(diskIO.write))

        case "net":
            let kindName = [InterfaceKind.wifi: "Wi-Fi", .ethernet: "以太网", .vpn: "VPN"][net.kind] ?? "网络"
            row("title", net.name.isEmpty ? "未连接" : "\(kindName) · \(net.name)")
            row("down", speedText(net.down))
            row("up", speedText(net.up))
            var ip = "—", router = "—"
            if let store, !net.name.isEmpty {
                if let v4 = SCDynamicStoreCopyValue(store, "State:/Network/Interface/\(net.name)/IPv4" as CFString) as? [String: Any],
                   let address = (v4["Addresses"] as? [String])?.first { ip = address }
                if let global = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
                   let gateway = global["Router"] as? String { router = gateway }
            }
            row("ip", ip)
            row("router", router)
            // Wi-Fi：信号、速率、信道（无线网络名称需要定位权限，macOS 不给）
            if let wifi = CWWiFiClient.shared().interface(), wifi.rssiValue() != 0 {
                let rssi = wifi.rssiValue()
                let quality = rssi >= -55 ? ("极好", green) : rssi >= -67 ? ("良好", green) : rssi >= -75 ? ("一般", yellow) : ("较差", red)
                row("signal", "\(rssi) dBm（\(quality.0)）", color: quality.1)
                row("rate", String(format: "%.0f Mbps", wifi.transmitRate()))
                if let channel = wifi.wlanChannel() {
                    let band = [CWChannelBand.band2GHz: "2.4 GHz", .band5GHz: "5 GHz", .band6GHz: "6 GHz"][channel.channelBand] ?? ""
                    row("channel", "\(channel.channelNumber)\(band.isEmpty ? "" : "（\(band)）")")
                }
                for name in ["signal", "rate", "channel"] { hide(name, false) }
            } else {
                for name in ["signal", "rate", "channel"] { hide(name, true) }
            }

        case "input":
            let sources = inputSources()
            for i in 0..<5 {
                if i < sources.count {
                    args += ["--set", "input.src.\(i)", "drawing=on", "icon=\(sources[i].current ? "\u{F043E}" : "\u{F043D}")",
                             "icon.color=\(sources[i].current ? yellow : "0xff5c6370")", "label=\(sources[i].name)",
                             "label.color=\(sources[i].current ? foreground : "0xff9c9c9c")"]
                } else {
                    hide("src.\(i)", true)
                }
            }

        case "volume":
            guard let device = outputDevice() else { break }
            row("title", device.name)
            if let volume = device.volume {
                let percent = Int((volume * 100).rounded())
                args += ["--set", "volume.slider", "drawing=on", "slider.percentage=\(percent)"]
                row("level", "\(percent)%")
            } else {
                hide("slider", true)
                row("level", "这个设备不能调音量", color: "0xff9c9c9c")
            }
            row("muted", device.muted == true ? "是" : "否", color: device.muted == true ? yellow : foreground)

        case "battery":
            guard let battery = batteryInfo() else { break }
            let percent = battery["CurrentCapacity"] as? Int ?? 0
            let charging = battery["IsCharging"] as? Bool ?? false
            let external = battery["ExternalConnected"] as? Bool ?? false
            let full = battery["FullyCharged"] as? Bool ?? false
            let state = full ? "已充满" : charging ? "充电中" : external ? "已接电源，未充电" : "使用电池"
            row("title", "电池 · \(state)")
            let charge = percent < 30 ? red : percent < 80 ? yellow : green   // 80% 以上绿，30–80% 黄，30% 以下红
            args += ["--set", "battery.bar", "slider.percentage=\(percent)", "slider.highlight_color=\(charge)"]
            row("level", "\(percent)%", color: charge)
            let minutes = charging ? battery["AvgTimeToFull"] as? Int : external ? nil : battery["AvgTimeToEmpty"] as? Int
            row("time", minutes.map { $0 >= 65535 ? "计算中…" : charging ? "\(durationText(minutes: $0))后充满" : "还能用 \(durationText(minutes: $0))" }
                ?? (full ? "—" : "—"))
            let watts = (battery["AdapterDetails"] as? [String: Any])?["Watts"] as? Int
            row("power", external ? (watts.map { "\($0) W 电源适配器" } ?? "电源适配器") : "电池")
            if let design = battery["DesignCapacity"] as? Int, design > 0, let max = battery["AppleRawMaxCapacity"] as? Int {
                let health = Double(max) / Double(design) * 100
                row("health", String(format: "%.0f%%（%d / %d mAh）", health, max, design), color: health < 80 ? yellow : foreground)
            }
            row("cycles", "\(battery["CycleCount"] as? Int ?? 0) 次")
            if let temperature = battery["Temperature"] as? Int {
                row("temp", String(format: "%.1f °C", Double(temperature) / 100))
            }

        case "clock":
            let now = Date()
            let calendar = Calendar.current
            row("title", formatted(now, "yMMMMdEEEE"))
            row("lunar", lunarDate(now))
            row("week", "第 \(calendar.component(.weekOfYear, from: now)) 周 · 今年第 \(calendar.ordinality(of: .day, in: .year, for: now) ?? 0) 天")
            let offset = TimeZone.current.secondsFromGMT() / 3600
            row("zone", "\(formatted(now, "zzzz"))（UTC\(offset >= 0 ? "+" : "")\(offset)）")

        default:
            break
        }
        return args
    }
}
