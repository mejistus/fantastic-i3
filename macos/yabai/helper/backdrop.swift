// SketchyBar 顶栏的底板（aero-helper bar-backdrop，由 ../../sketchybar/sketchybarrc 启动）
//
// 原生菜单栏的"磨砂"其实是壁纸：屏幕顶上那块壁纸用很大的半径（约 300 pt）模糊、略微压暗，所以壁纸亮的地方亮、
// 暗的地方几乎是黑的，中间平滑过渡，身后的窗口不会透出来。这里照着做：每块屏顶上放一条和栏一样大的窗口，
// 贴上这样算出来的图（参数和截下来的原生菜单栏逐段比对过）。读不到壁纸（动态壁纸等）时退回系统的磨砂材质。
// SketchyBar 自己的 blur_radius 用的私有接口在 macOS 15 上对它的窗口不起作用，所以不用它。
//
// 窗口层级 2：普通窗口（0）之上，SketchyBar 的栏（topmost=window，浮动窗口层级 3）之下。不接收鼠标。
// 每条只放在自己那块屏的普通桌面上，不放在原生全屏的桌面上（SketchyBar 在那上面也不画栏），见 placeOnDesktops。
// 每 3 秒问一次 SketchyBar 栏的高度和是否隐藏，顺便看壁纸换没换（切换桌面时也看，每个桌面可以有不同的壁纸）。
// 问不到时看 SketchyBar 的进程还在不在，不在了才退出：刚启动时它往往还在执行 sketchybarrc，睡眠唤醒后也要重建栏，
// 这些时候都问不到（之前连着问不到 3 次就退出，唤醒后底板就没了）。
// 换壁纸、换屏时窗口留着重用，只换位置和图（不闪）；问 SketchyBar、读壁纸、模糊都在后台做，不卡主线程。

import AppKit
import CoreImage

// 某块屏现在显示的桌面和它的类型（4 = 原生全屏），SketchyBar 也是这么判断的
@_silgen_name("CGSManagedDisplayGetCurrentSpace")
func CGSManagedDisplayGetCurrentSpace(_ cid: Int32, _ display: CFString) -> UInt64
@_silgen_name("CGSSpaceGetType")
func CGSSpaceGetType(_ cid: Int32, _ space: UInt64) -> Int32
// 各块屏上有哪些桌面（每块屏一项，"Spaces" 里 type 0 是普通桌面，4 是原生全屏），以及把窗口放到哪些桌面上
@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ cid: Int32) -> Unmanaged<CFArray>?
@_silgen_name("CGSCopySpacesForWindows")
func CGSCopySpacesForWindows(_ cid: Int32, _ mask: Int32, _ windows: CFArray) -> Unmanaged<CFArray>?
@_silgen_name("CGSAddWindowsToSpaces")
func CGSAddWindowsToSpaces(_ cid: Int32, _ windows: CFArray, _ spaces: CFArray)
@_silgen_name("CGSRemoveWindowsFromSpaces")
func CGSRemoveWindowsFromSpaces(_ cid: Int32, _ windows: CFArray, _ spaces: CFArray)

final class BarBackdrop {
    let sketchybar = "/opt/homebrew/bin/sketchybar"
    // 在 sRGB（带 gamma）里模糊和压暗，和比对时的算法一致
    let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
    let work = DispatchQueue(label: "bar-backdrop", qos: .utility)
    var windows: [CGDirectDisplayID: NSWindow] = [:]   // 每块屏一条
    var height: CGFloat = 0
    var hidden = false
    var wallpapers = ""   // 各屏的位置、壁纸路径和修改时间；变了就重画
    var generation = 0    // 第几次重画：后台算得慢的旧图不要

    func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)   // 不出现在程序坞和 ⌘⇥ 里，yabai 也不管它
        sync()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.rebuild() }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification,
                                                          object: nil, queue: .main) { [weak self] _ in
            self?.placeOnDesktops()   // 新加的桌面
            self?.checkWallpaper()
        }
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.sync() }
        app.run()
    }

    /// 按 SketchyBar 现在的栏高和是否隐藏更新底板（在后台问，问完回主线程）
    func sync() {
        work.async { [weak self] in
            guard let self else { return }
            let bar = self.queryBar()
            let running = bar != nil || sketchybarRunning()
            DispatchQueue.main.async { self.apply(bar, running: running) }
        }
    }

    func apply(_ bar: [String: Any]?, running: Bool) {
        guard let bar else {
            if !running {
                logLine("bar-backdrop 退出：SketchyBar 不在了")
                exit(0)
            }
            if windows.isEmpty { height = 24; rebuild() }   // 先按 24 高建出来
            return
        }
        let newHeight = CGFloat((bar["height"] as? NSNumber)?.doubleValue ?? 24)
        let newHidden = (bar["hidden"] as? String) == "on" || (bar["position"] as? String) == "bottom"
        if newHeight != height || newHidden != hidden || windows.isEmpty {
            height = newHeight
            hidden = newHidden
            rebuild()
        } else {
            placeOnDesktops()
            checkWallpaper()
        }
    }

    func queryBar() -> [String: Any]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sketchybar)
        process.arguments = ["--query", "bar"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    func wallpaperSignature() -> String {
        NSScreen.screens.map { screen in
            let url = NSWorkspace.shared.desktopImageURL(for: screen)
            let modified = (try? url?.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            return "\(screen.frame) \(url?.path ?? "-") \(modified?.timeIntervalSince1970 ?? 0)"
        }.joined(separator: "\n")
    }

    /// 全屏时不看：壁纸反正看不到，系统报的也不一定是桌面上那张，等退出全屏再说
    func checkWallpaper() {
        if !hidden, fullscreenDisplays().isEmpty, wallpaperSignature() != wallpapers { rebuild() }
    }

    func displayID(_ screen: NSScreen) -> CGDirectDisplayID? {
        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    /// 现在显示着原生全屏桌面的屏
    func fullscreenDisplays() -> Set<CGDirectDisplayID> {
        let cid = CGSMainConnectionID()
        return Set(NSScreen.screens.compactMap(displayID).filter { display in
            guard let uuid = CGDisplayCreateUUIDFromDisplayID(display)?.takeRetainedValue(),
                  let name = CFUUIDCreateString(nil, uuid) else { return false }
            return CGSSpaceGetType(cid, CGSManagedDisplayGetCurrentSpace(cid, name)) == 4
        })
    }

    /// 每条底板放到自己那块屏的所有普通桌面上，从别的桌面（原生全屏的）上拿掉。
    /// 不用"所有桌面都显示"（canJoinAllSpaces）：那样系统会把它也放到新建的全屏桌面上，进入全屏的一瞬间先画出来，
    /// 等收到切换桌面的通知再藏已经晚了约 90 ms，顶上闪一下磨砂（录屏逐帧看过）。新加的普通桌面在下次检查时补上
    func placeOnDesktops() {
        let cid = CGSMainConnectionID()
        guard let displays = CGSCopyManagedDisplaySpaces(cid)?.takeRetainedValue() as? [[String: Any]] else { return }
        for (display, window) in windows {
            guard let uuid = CGDisplayCreateUUIDFromDisplayID(display)?.takeRetainedValue(),
                  let name = CFUUIDCreateString(nil, uuid) as String? else { continue }
            // "显示器使用不同空间"关掉时只有一项，叫 Main
            let entry = displays.first { $0["Display Identifier"] as? String == name }
                ?? displays.first { $0["Display Identifier"] as? String == "Main" }
            let spaces = entry?["Spaces"] as? [[String: Any]] ?? []
            let desktops = Set(spaces.filter { $0["type"] as? Int == 0 }.compactMap { $0["id64"] as? Int })
            let ids = [window.windowNumber] as CFArray
            let current = Set(CGSCopySpacesForWindows(cid, 7, ids)?.takeRetainedValue() as? [Int] ?? [])
            let add = desktops.subtracting(current), remove = current.subtracting(desktops)
            if !add.isEmpty { CGSAddWindowsToSpaces(cid, ids, Array(add) as CFArray) }
            if !remove.isEmpty { CGSRemoveWindowsFromSpaces(cid, ids, Array(remove) as CFArray) }
        }
    }

    /// 每块屏一条：贴着屏幕顶边，宽同屏幕，高同栏。已有的窗口只挪位置，图在后台算好再换上
    func rebuild() {
        wallpapers = wallpaperSignature()
        generation += 1
        var screens: [CGDirectDisplayID: NSScreen] = [:]
        for screen in NSScreen.screens { if let display = displayID(screen) { screens[display] = screen } }
        for (display, window) in windows where hidden || height <= 0 || screens[display] == nil {
            window.orderOut(nil)
            windows[display] = nil
        }
        guard !hidden, height > 0 else { return }
        var jobs: [(display: CGDirectDisplayID, wallpaper: URL?, size: CGSize)] = []
        for (display, screen) in screens {
            let frame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - height, width: screen.frame.width, height: height)
            if let window = windows[display] {
                window.setFrame(frame, display: false)
            } else {
                windows[display] = makeWindow(frame)
            }
            jobs.append((display, NSWorkspace.shared.desktopImageURL(for: screen), screen.frame.size))
        }
        placeOnDesktops()
        let generation = self.generation, height = self.height
        work.async { [weak self] in
            guard let self else { return }
            let strips = jobs.map { ($0.display, self.wallpaperStrip($0.wallpaper, screen: $0.size, height: height)) }
            DispatchQueue.main.async {
                guard generation == self.generation else { return }
                for (display, strip) in strips {
                    if let window = self.windows[display] { self.fill(window, with: strip) }
                }
            }
        }
    }

    func makeWindow(_ frame: NSRect) -> NSWindow {
        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.level = NSWindow.Level(rawValue: 2)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.stationary, .ignoresCycle]   // 放在哪些桌面上由 placeOnDesktops 管
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = nil   // 图画好之前什么都不画
        window.orderFrontRegardless()
        return window
    }

    func fill(_ window: NSWindow, with strip: CGImage?) {
        let bounds = NSRect(origin: .zero, size: window.frame.size)
        if let strip {
            let view = NSView(frame: bounds)
            view.wantsLayer = true
            view.layer?.contents = strip
            view.layer?.contentsGravity = .resize   // 按 1/4 分辨率算的，拉伸回来（本来就糊，看不出）
            window.contentView = view
        } else {
            let glass = NSVisualEffectView(frame: bounds)
            glass.material = .hudWindow   // 系统材质里和原生菜单栏最接近的
            glass.blendingMode = .behindWindow
            glass.state = .active
            window.contentView = glass
        }
    }

    /// 屏幕顶上那块壁纸模糊、压暗后的样子。按 1/4 分辨率算：模糊半径这么大，细节反正都没了。后台线程里调用
    func wallpaperStrip(_ url: URL?, screen: CGSize, height: CGFloat) -> CGImage? {
        guard let url, let image = CIImage(contentsOf: url),
              image.extent.width > 0, image.extent.height > 0 else { return nil }
        let k: CGFloat = 0.25
        let size = CGSize(width: screen.width * k, height: screen.height * k)
        // 铺满屏幕、居中裁掉多出来的部分（系统设置里的"填充屏幕"）
        let scale = max(size.width / image.extent.width, size.height / image.extent.height)
        let placed = image
            .transformed(by: CGAffineTransform(translationX: -image.extent.minX, y: -image.extent.minY))
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: (size.width - image.extent.width * scale) / 2,
                                               y: (size.height - image.extent.height * scale) / 2))
        let strip = CGRect(x: 0, y: size.height - height * k, width: size.width, height: height * k)
        let darken = CIVector(x: -10 / 255, y: -10 / 255, z: -10 / 255, w: 0)
        let blurred = placed.clampedToExtent()
            .applyingGaussianBlur(sigma: 300 * k)
            .applyingFilter("CIColorMatrix", parameters: ["inputBiasVector": darken])
            .cropped(to: strip)
        return context.createCGImage(blurred, from: strip)
    }
}
