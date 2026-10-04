import SwiftUI

@main
struct ScreenLightApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    private let light = Light.shared

    private var menuBarLabel: String {
        let s = Model.shared.s
        return switch light.mode {
        case .off: Model.appName
        case .full: Model.appName + ", " + s.light
        case .edge, .booth: Model.appName + ", " + s.edge
        }
    }

    var body: some Scene {
        Window(Text(Model.appName), id: "main") {
            OptionsView()
                .windowFullScreenBehavior(.disabled)
        }
        .windowResizability(.contentSize)
        .windowBackgroundDragBehavior(.enabled)
        .defaultSize(width: 460, height: 820)
        // The helper that runs in the background has no window of its own.
        .defaultLaunchBehavior(Background.isHelper ? .suppressed : .presented)
        // The app menu like Photo Booth's: About, Hide, Hide Others, Show All, Quit, no Services.
        .commands { CommandGroup(replacing: .systemServices) {} }

        // Always there; hiding it is System Settings → Menu Bar's job, and it keeps its place.
        MenuBarExtra {
            MenuPanel()
        } label: {
            Image(systemName: light.mode == .off ? "sun.max" : "sun.max.fill")
                // What macOS reads out and shows when you hold ⌘ over the icon: the name, then
                // the state, like the system's own "Wi-Fi, connected, 3 bars".
                .accessibilityLabel(menuBarLabel)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if Background.isHelper {
            Background.quitOnSignal()
        } else {
            Background.takeOver()
            // Opening the app opens its window, also when it was closed at the last quit.
            DispatchQueue.main.async { self.showWindow() }
        }
        Model.shared.start()
        PhotoBooth.start()
        Light.shared.resume()
    }

    /// The panel's Quit, which puts out the light too, not just the window.
    static var quitNow = false

    // Closing the window keeps the app alive in the menu bar.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showWindow() }
        return true
    }

    private func showWindow() {
        guard !NSApp.windows.contains(where: { $0.isVisible && $0.canBecomeMain }) else { return }
        // The Window menu's own item for the window, as clicking it would: SwiftUI's openWindow
        // does nothing when the app was launched without showing it.
        if let menu = NSApp.windowsMenu,
           let i = menu.items.firstIndex(where: { $0.title == Model.appName }) {
            menu.performActionForItem(at: i)
        } else {
            Model.shared.openMain?()
        }
    }

    // Quit from the Dock or with ⌘Q: the helper carries on in the background (Background.swift)
    // and keeps the light. Quitting from the panel, at logout, restart or shutdown (they put
    // 'why?' on the quit event) or with Stop Running in Background puts the backlight back
    // where it was.
    func applicationWillTerminate(_ notification: Notification) {
        let why = NSAppleEventManager.shared().currentAppleEvent?.attributeDescriptor(forKeyword: 0x7768_793F)
        if Background.isHelper {
            if !Background.handingBack { Light.shared.off() }
        } else if !Self.quitNow, why == nil {
            Background.handOver()
        } else {
            Light.shared.off()
        }
    }
}
