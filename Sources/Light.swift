import SwiftUI

/// The built-in display's backlight through the private `DisplayServices` framework, the only
/// way to drive it on Apple Silicon. If the symbols ever go away every call is a no-op and the
/// on-screen light still works.
enum Backlight {
    private typealias SetFn = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private typealias GetFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

    private static let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
    private static let setFn = dlsym(handle, "DisplayServicesSetBrightness").map { unsafeBitCast($0, to: SetFn.self) }
    private static let getFn = dlsym(handle, "DisplayServicesGetBrightness").map { unsafeBitCast($0, to: GetFn.self) }

    /// `value` is 0...100.
    static func set(_ value: Double) {
        _ = setFn?(CGMainDisplayID(), Float(min(max(value, 0), 100) / 100))
    }

    static func get() -> Double? {
        var level: Float = 0
        guard let getFn, getFn(CGMainDisplayID(), &level) == 0 else { return nil }
        return Double(level) * 100
    }
}

/// The light itself. `full` fills every screen and goes away on any key or click; `edge` draws
/// a frame of light around every screen and lets clicks through; `booth` is the edge light
/// Photo Booth turns on: a frame on Photo Booth's screen, every other screen filled.
@Observable
final class Light {
    static let shared = Light()
    enum Mode { case off, full, edge, booth }

    private(set) var mode = Mode.off
    /// The pointer while it is near a frame, in screen coordinates; nil elsewhere, so moving
    /// the mouse around the middle of the screen redraws nothing.
    private(set) var pointer: CGPoint?

    @ObservationIgnored private var windows: [NSWindow] = []
    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored private var pointerMonitors: [Any] = []
    @ObservationIgnored private var savedBacklight: Double?
    @ObservationIgnored private var savedOptions: NSApplication.PresentationOptions?
    @ObservationIgnored private var boothScreen: NSScreen?

    func toggle(_ m: Mode) {
        mode == m ? off() : show(m)
    }

    func show(_ newMode: Mode, boothScreen screen: NSScreen? = nil) {
        if newMode == .booth, mode == .booth, screen == boothScreen { return }
        tearDown()
        mode = newMode
        boothScreen = screen
        if savedBacklight == nil { savedBacklight = Backlight.get() }
        Backlight.set(Model.shared.brightness)

        let full = newMode == .full
        for s in NSScreen.screens {
            let ring = newMode == .edge || (newMode == .booth && (screen == nil || s == screen))
            windows.append(makeWindow(on: s, ring: ring, interactive: full))
        }

        guard full else {
            windows.forEach { $0.orderFrontRegardless() }
            trackPointer()
            return
        }
        // The first window becomes key so key presses reach the monitor below.
        windows.first?.makeKeyAndOrderFront(nil)
        windows.dropFirst().forEach { $0.orderFrontRegardless() }
        savedOptions = NSApp.presentationOptions
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]
        NSApp.activate()
        NSCursor.setHiddenUntilMouseMoves(true)
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            self?.off()
            return nil
        }
    }

    func off() {
        guard mode != .off else { return }
        tearDown()
        mode = .off
        boothScreen = nil
        if let b = savedBacklight {
            Backlight.set(b)
            savedBacklight = nil
        }
    }

    /// Color and frame width reach the windows by themselves (`LightView` reads the model);
    /// only the backlight needs a push.
    func refresh() {
        if mode != .off { Backlight.set(Model.shared.brightness) }
    }

    /// Frame thickness on a screen; the view and the pointer tracking use the same numbers.
    static func band(on screen: CGRect) -> CGFloat {
        min(screen.width, screen.height) * Model.shared.edgeWidth
    }

    // The look of the Edge Light, in points. Tune here.
    /// Soft edge of the whole band, as a share of its width.
    static let bandBlur: CGFloat = 0.18
    /// Around the pointer the band is gone completely within this radius: a clear gap,
    /// not a dimmed patch.
    static let pointerGap: CGFloat = 120
    /// Then it comes back over this distance, softly.
    static let pointerBlur: CGFloat = 70

    /// The menu bar's height on a screen; like the system's Edge Light, the band starts below it.
    static func menuBar(on screen: NSScreen) -> CGFloat { screen.frame.maxY - screen.visibleFrame.maxY }

    /// 1 while the band is within the pointer's gap, easing to 0 over the blur beyond it.
    static func fade(at p: CGPoint, on screen: NSScreen) -> CGFloat {
        let f = screen.frame
        let w = band(on: f)
        guard f.contains(p) else { return 0 }
        let d = min(p.x - f.minX, f.maxX - p.x, p.y - f.minY, f.maxY - menuBar(on: screen) - p.y)
        return min(max((w + pointerGap + pointerBlur - d) / pointerBlur, 0), 1)
    }

    /// Mouse moves reach us from other apps too; watching them needs no permission.
    private func trackPointer() {
        let moves: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        if let g = NSEvent.addGlobalMonitorForEvents(matching: moves, handler: { _ in
            MainActor.assumeIsolated { Light.shared.pointerMoved() }
        }) { pointerMonitors.append(g) }
        if let l = NSEvent.addLocalMonitorForEvents(matching: moves, handler: { e in
            Light.shared.pointerMoved()
            return e
        }) { pointerMonitors.append(l) }
        pointerMoved()
    }

    private func pointerMoved() {
        let p = NSEvent.mouseLocation
        let near = NSScreen.screens.contains { Light.fade(at: p, on: $0) > 0 }
        let new = near ? p : nil
        if new != pointer { pointer = new }
    }

    private func tearDown() {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
        pointerMonitors.forEach { NSEvent.removeMonitor($0) }
        pointerMonitors.removeAll()
        pointer = nil
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        if let o = savedOptions {
            NSApp.presentationOptions = o
            savedOptions = nil
        }
    }

    private func makeWindow(on screen: NSScreen, ring: Bool, interactive: Bool) -> NSWindow {
        let w = LightWindow(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        w.isReleasedWhenClosed = false
        w.hidesOnDeactivate = false
        // Like the system's Edge Light, the light never shows up in screenshots or recordings.
        w.sharingType = .none
        w.level = interactive ? NSWindow.Level(Int(CGShieldingWindowLevel())) : .screenSaver
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        w.isOpaque = !ring
        w.backgroundColor = .clear
        w.hasShadow = false
        w.ignoresMouseEvents = !interactive
        let host = NSHostingView(rootView: LightView(ring: ring, screen: screen))
        host.sizingOptions = []
        w.contentView = host
        w.setFrame(screen.frame, display: false)
        return w
    }
}

/// A panel that doesn't activate the app: only such windows can join the Space of another
/// app's full-screen window. It can still become key, which the full light needs for keys.
final class LightWindow: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// One screen's light. The frame follows the system's Edge Light: a thick band with rounded
/// corners, a bright core and soft edges, starting below the menu bar. Where the pointer
/// comes near, the band fades away, more the closer it gets, and comes back as it leaves.
struct LightView: View {
    let ring: Bool
    let screen: NSScreen

    var body: some View {
        let m = Model.shared
        let w = Light.band(on: screen.frame)
        Rectangle().fill(m.color).mask {
            if ring {
                ZStack {
                    Band(width: w)
                    PointerFade(screen: screen, width: w)
                }
                .compositingGroup()
                .padding(.top, Light.menuBar(on: screen))
            } else {
                Rectangle()
            }
        }
        .ignoresSafeArea()
    }
}

/// The band itself, kept apart from the pointer so moving the mouse doesn't redraw its blur.
private struct Band: View {
    let width: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: width * 1.1 + 24, style: .continuous).inset(by: width / 2)
        ZStack {
            shape.stroke(lineWidth: width).blur(radius: width * Light.bandBlur)
            shape.stroke(lineWidth: width * 0.7)
        }
    }
}

private struct PointerFade: View {
    let screen: NSScreen
    let width: CGFloat

    var body: some View {
        if let p = Light.shared.pointer, screen.frame.contains(p) {
            let strength = Light.fade(at: p, on: screen)
            let r = Light.pointerGap + Light.pointerBlur
            let gap = Light.pointerGap / r
            // Full clearance inside the gap, then an eased fall-off; the whole hole grows
            // stronger as the pointer comes near the band.
            Circle()
                .fill(RadialGradient(stops: [.init(color: .black.opacity(strength), location: 0),
                                             .init(color: .black.opacity(strength), location: gap),
                                             .init(color: .black.opacity(strength * 0.5), location: gap + (1 - gap) * 0.4),
                                             .init(color: .clear, location: 1)],
                                     center: .center, startRadius: 0, endRadius: r))
                .frame(width: r * 2, height: r * 2)
                // Screen coordinates start at the bottom, the view's at the top, below the menu bar.
                .position(x: p.x - screen.frame.minX,
                          y: screen.frame.maxY - Light.menuBar(on: screen) - p.y)
                .blendMode(.destinationOut)
        }
    }
}

/// Turns the edge light on while Photo Booth is in front. Driven by workspace notifications,
/// nothing polls.
enum PhotoBooth {
    static let bundleID = "com.apple.PhotoBooth"

    static func start() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated { frontChanged(app) }
        }
        nc.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                if app?.bundleIdentifier == bundleID, Light.shared.mode == .booth { Light.shared.off() }
            }
        }
        check()
    }

    static func check() {
        frontChanged(NSWorkspace.shared.frontmostApplication)
    }

    private static func frontChanged(_ app: NSRunningApplication?) {
        let light = Light.shared
        if let app, app.bundleIdentifier == bundleID, Model.shared.photoBooth {
            guard light.mode != .full else { return }
            let pid = app.processIdentifier
            light.show(.booth, boothScreen: screen(of: pid))
            // A Photo Booth that is just launching has no window yet; look once more.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                MainActor.assumeIsolated {
                    guard light.mode == .booth, NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return }
                    light.show(.booth, boothScreen: screen(of: pid))
                }
            }
        } else if light.mode == .booth,
                  app?.processIdentifier != ProcessInfo.processInfo.processIdentifier || !Model.shared.photoBooth {
            // Switching to this app itself (e.g. the menu bar panel) keeps the light on.
            light.off()
        }
    }

    /// The screen under Photo Booth's largest window. Window bounds need no permission.
    private static func screen(of pid: pid_t) -> NSScreen? {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] else { return nil }
        let rects = list.compactMap { info -> CGRect? in
            guard info[kCGWindowOwnerPID as String] as? pid_t == pid,
                  info[kCGWindowLayer as String] as? Int == 0,
                  let b = info[kCGWindowBounds as String] as? NSDictionary else { return nil }
            return CGRect(dictionaryRepresentation: b)
        }
        guard let r = rects.max(by: { $0.width * $0.height < $1.width * $1.height }),
              let primary = NSScreen.screens.first else { return nil }
        // Window bounds start at the primary screen's top-left corner, NSScreen at its bottom-left.
        let center = CGPoint(x: r.midX, y: primary.frame.maxY - r.midY)
        return NSScreen.screens.first { $0.frame.contains(center) }
    }
}
