import AppKit

/// A borderless window that is allowed to become key so it can receive key/mouse events
/// while it covers the screen.
final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Drives the fullscreen light: applies hardware brightness, shows an opaque color overlay on
/// every screen, and watches for any key/mouse/trackpad event to dismiss and restore state.
final class LightController {
    static let shared = LightController()
    private init() {}

    private var windows: [NSWindow] = []
    private var monitor: Any?
    private var savedBrightness: Double?
    private var savedPresentationOptions: NSApplication.PresentationOptions?
    private weak var optionsWindow: NSWindow?

    private(set) var isLightOn = false

    func showLight(color: NSColor, brightness: Double, optionsWindow: NSWindow?) {
        guard !isLightOn else { return }
        isLightOn = true
        self.optionsWindow = optionsWindow

        // Remember the current brightness, then apply the requested level.
        savedBrightness = Brightness.get()
        Brightness.set(brightness)

        // Hide the options window (don't close it — we reuse it on dismiss).
        optionsWindow?.orderOut(nil)

        // One opaque overlay per screen, above the menu bar.
        for screen in NSScreen.screens {
            let w = OverlayWindow(contentRect: screen.frame,
                                  styleMask: .borderless,
                                  backing: .buffered,
                                  defer: false)
            w.isReleasedWhenClosed = false
            w.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            w.backgroundColor = color
            w.isOpaque = true
            w.hasShadow = false
            w.setFrame(screen.frame, display: true)
            windows.append(w)
        }

        // The first window becomes key so keyDown events are delivered to our app.
        windows.first?.makeKeyAndOrderFront(nil)
        for w in windows.dropFirst() { w.orderFrontRegardless() }

        savedPresentationOptions = NSApp.presentationOptions
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]
        NSApp.activate(ignoringOtherApps: true)

        // Any key, modifier, or mouse/trackpad click returns to the options screen.
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            self?.dismiss()
            return nil // swallow the event
        }
    }

    func dismiss() {
        guard isLightOn else { return }
        isLightOn = false

        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }

        for w in windows {
            w.orderOut(nil)
            w.close()
        }
        windows.removeAll()

        if let opts = savedPresentationOptions {
            NSApp.presentationOptions = opts
            savedPresentationOptions = nil
        }

        restoreIfNeeded()

        optionsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Put the backlight back to the value saved before the light was turned on.
    func restoreIfNeeded() {
        if let b = savedBrightness {
            Brightness.set(b)
            savedBrightness = nil
        }
    }
}
