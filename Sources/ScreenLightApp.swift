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
        .defaultLaunchBehavior(.presented)
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
        Model.shared.start()
        PhotoBooth.start()
    }

    // Closing the window keeps the app alive in the menu bar.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { Model.shared.openMain?() }
        return true
    }

    // Quitting with the light on puts the backlight back where it was.
    func applicationWillTerminate(_ notification: Notification) {
        Light.shared.off()
    }
}
