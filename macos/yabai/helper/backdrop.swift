// SketchyBar 顶栏的底板（aero-helper bar-backdrop，由 ../../sketchybar/sketchybarrc 启动）
//
// 原生菜单栏的"磨砂"其实是壁纸：屏幕顶上那块壁纸用很大的半径（约 300 pt）模糊、略微压暗，所以壁纸亮的地方亮、
// 暗的地方几乎是黑的，中间平滑过渡，身后的窗口不会透出来。这里照着做：每块屏顶上放一条和栏一样大的窗口，
// 贴上这样算出来的图（参数和截下来的原生菜单栏逐段比对过）。读不到壁纸（动态壁纸等）时退回系统的磨砂材质。
// SketchyBar 自己的 blur_radius 用的私有接口在 macOS 15 上对它的窗口不起作用，所以不用它。
//
// 窗口层级 2：普通窗口（0）之上，SketchyBar 的栏（topmost=window，浮动窗口层级 3）之下。不接收鼠标。
// 每条只放在自己那块屏的普通桌面上，不放在原生全屏的桌面上（SketchyBar 在那上面也不画栏），见 placeOnDesktops。
// 不走原生全屏、而是用一个窗口盖满整块屏的（PowerPoint 放映等），把栏和底板一起藏起来，见 checkCovered。
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
    var covered = false   // 有窗口盖满了某块屏，栏和底板都藏起来了（见 checkCovered）

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
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in self?.checkCovered() }.tolerance = 0.05
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
        // 栏藏不藏由这里管（见 checkCovered）：SketchyBar 重载过、或者上次没发成功，就再发一次
        if ((bar["hidden"] as? String) == "on") != covered { hideBar() }
        let newHeight = CGFloat((bar["height"] as? NSNumber)?.doubleValue ?? 24)
        let newHidden = (bar["position"] as? String) == "bottom"
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

    /// PowerPoint 放映（还有不走原生全屏的视频、游戏）是普通桌面上一个层级 0、盖满整块屏的窗口。SketchyBar 只在原生全屏的
    /// 桌面上藏栏，管不到这种；栏和底板又都在普通窗口之上，就压在放映的画面上。这时把两者都藏起来（hidden=on，底板透明）。
    /// SketchyBar 从命令行只能所有屏一起藏，所以另一块屏上的栏也跟着藏（放映时那块屏多半是演示者视图，本来也被盖着）。
    /// 不用 topmost=off 降到普通窗口下面：SketchyBar 改 topmost 会拆掉重建所有栏的窗口（一个图标一个窗口），
    /// 图标一个接一个地消失，前后拖 0.2 秒，恢复时整条栏还要闪一下（逐帧量过）；hidden 是所有窗口同时挪走。
    /// 每 0.2 秒看一次窗口列表（约 0.5 ms）：放映开始时程序没有切换、桌面也没变，没有通知可等
    func checkCovered() {
        guard coveredByWindow() != covered else { return }
        covered.toggle()
        logLine(covered ? "bar-backdrop：有窗口盖满了屏幕，藏起栏" : "bar-backdrop：栏回来")
        hideBar()
    }

    /// 栏按 covered 藏起来或放出来，SketchyBar 照做了再藏 / 放底板：两者一起消失、一起出现
    func hideBar() {
        let hide = covered
        work.async { [weak self, sketchybar] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: sketchybar)
            process.arguments = ["--bar", "hidden=\(hide ? "on" : "off")"]
            try? process.run()
            process.waitUntilExit()
            DispatchQueue.main.async {
                guard let self else { return }
                for window in self.windows.values { window.alphaValue = self.covered ? 0 : 1 }
            }
        }
    }

    /// 有没有哪块屏（原生全屏的除外）最上面的普通窗口正好盖满整块屏。没开"自动隐藏程序坞"时，最大化的窗口盖不到程序坞那一截
    func coveredByWindow() -> Bool {
        let skip = fullscreenDisplays()
        let displays = NSScreen.screens.compactMap(displayID).filter { !skip.contains($0) }.map(CGDisplayBounds)
        guard !displays.isEmpty else { return false }
        let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        var done = Set<Int>()   // 已经找到最上面那个窗口的屏
        for window in info {    // 从前往后
            guard window[kCGWindowLayer as String] as? Int == 0,
                  (window[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                  let dict = window[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: dict as CFDictionary),
                  bounds.width >= 100, bounds.height >= 100 else { continue }   // 不算看不见的小窗口
            for (i, display) in displays.enumerated() where !done.contains(i) && bounds.intersects(display) {
                if bounds.contains(display) { return true }
                done.insert(i)
            }
            if done.count == displays.count { break }
        }
        return false
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
        window.alphaValue = covered ? 0 : 1
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
        // 取整：内置屏高 1050，× 0.25 = 262.5，边上那半个像素是半透明的，clampedToExtent 再把它往外铺开，
        // 糊出来整条都半透明（看着就是栏透明了）。所以尺寸取整，铺好的图也只留屏幕范围内整像素的部分
        let size = CGSize(width: floor(screen.width * k), height: floor(screen.height * k))
        // 铺满屏幕、居中裁掉多出来的部分（系统设置里的"填充屏幕"）
        let scale = max(size.width / image.extent.width, size.height / image.extent.height)
        let placed = image
            .transformed(by: CGAffineTransform(translationX: -image.extent.minX, y: -image.extent.minY))
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: (size.width - image.extent.width * scale) / 2,
                                               y: (size.height - image.extent.height * scale) / 2))
            .cropped(to: CGRect(origin: .zero, size: size))
        let strip = CGRect(x: 0, y: size.height - height * k, width: size.width, height: height * k)
        let darken = CIVector(x: -10 / 255, y: -10 / 255, z: -10 / 255, w: 0)
        let blurred = placed.clampedToExtent()
            .applyingGaussianBlur(sigma: 300 * k)
            .applyingFilter("CIColorMatrix", parameters: ["inputBiasVector": darken])
            .cropped(to: strip)
        return context.createCGImage(blurred, from: strip)
    }
}
