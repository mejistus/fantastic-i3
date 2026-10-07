// SketchyBar 顶栏的底板（aero-helper bar-backdrop，由 ../../sketchybar/sketchybarrc 启动）
//
// 原生菜单栏的"磨砂"其实是壁纸：屏幕顶上那块壁纸用很大的半径（约 300 pt）模糊、略微压暗，所以壁纸亮的地方亮、
// 暗的地方几乎是黑的，中间平滑过渡，身后的窗口不会透出来。这里照着做：每块屏顶上放一条和栏一样大的窗口，
// 贴上这样算出来的图（参数和截下来的原生菜单栏逐段比对过）。读不到壁纸（动态壁纸等）时退回系统的磨砂材质。
// SketchyBar 自己的 blur_radius 用的私有接口在 macOS 15 上对它的窗口不起作用，所以不用它。
//
// 窗口层级 2：普通窗口（0）之上，SketchyBar 的栏（topmost=window，浮动窗口层级 3）之下。不接收鼠标，
// 所有桌面都显示。每 3 秒问一次 SketchyBar 栏的高度和是否隐藏，顺便看壁纸换没换（切换桌面时也看，
// 每个桌面可以有不同的壁纸）；连着 3 次问不到（SketchyBar 不在了）就退出。
// 刚启动时 SketchyBar 往往还在执行 sketchybarrc，问不到是正常的，先按 24 高建出来。

import AppKit
import CoreImage

final class BarBackdrop {
    let sketchybar = "/opt/homebrew/bin/sketchybar"
    // 在 sRGB（带 gamma）里模糊和压暗，和比对时的算法一致
    let context = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
    var windows: [NSWindow] = []
    var height: CGFloat = 0
    var hidden = false
    var failures = 0
    var wallpapers = ""   // 各屏的位置、壁纸路径和修改时间；变了就重画

    func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)   // 不出现在程序坞和 ⌘⇥ 里，yabai 也不管它
        sync()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.rebuild() }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification,
                                                          object: nil, queue: .main) { [weak self] _ in self?.checkWallpaper() }
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.sync() }
        app.run()
    }

    /// 按 SketchyBar 现在的栏高和是否隐藏更新底板；连着 3 次问不到就退出
    func sync() {
        guard let bar = queryBar() else {
            failures += 1
            if failures >= 3 { exit(0) }
            if windows.isEmpty { height = 24; rebuild() }
            return
        }
        failures = 0
        let newHeight = CGFloat((bar["height"] as? NSNumber)?.doubleValue ?? 24)
        let newHidden = (bar["hidden"] as? String) == "on" || (bar["position"] as? String) == "bottom"
        if newHeight != height || newHidden != hidden || windows.isEmpty {
            height = newHeight
            hidden = newHidden
            rebuild()
        } else {
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

    func checkWallpaper() {
        if !hidden, wallpaperSignature() != wallpapers { rebuild() }
    }

    /// 每块屏一条：贴着屏幕顶边，宽同屏幕，高同栏
    func rebuild() {
        windows.forEach { $0.orderOut(nil) }
        windows = []
        wallpapers = wallpaperSignature()
        guard !hidden, height > 0 else { return }
        for screen in NSScreen.screens {
            let frame = NSRect(x: screen.frame.minX, y: screen.frame.maxY - height, width: screen.frame.width, height: height)
            let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.level = NSWindow.Level(rawValue: 2)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            let bounds = NSRect(origin: .zero, size: frame.size)
            if let strip = wallpaperStrip(screen) {
                let view = NSView(frame: bounds)
                view.wantsLayer = true
                view.layer?.contents = strip
                view.layer?.contentsGravity = .resize   // 按 1/4 分辨率算的，拉伸回来（本来就糊，看不出）
                window.contentView = view
            } else {
                window.appearance = NSAppearance(named: .darkAqua)
                let glass = NSVisualEffectView(frame: bounds)
                glass.material = .hudWindow   // 系统材质里和原生菜单栏最接近的
                glass.blendingMode = .behindWindow
                glass.state = .active
                window.contentView = glass
            }
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    /// 屏幕顶上那块壁纸模糊、压暗后的样子。按 1/4 分辨率算：模糊半径这么大，细节反正都没了
    func wallpaperStrip(_ screen: NSScreen) -> CGImage? {
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen), let image = CIImage(contentsOf: url),
              image.extent.width > 0, image.extent.height > 0 else { return nil }
        let k: CGFloat = 0.25
        let size = CGSize(width: screen.frame.width * k, height: screen.frame.height * k)
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
