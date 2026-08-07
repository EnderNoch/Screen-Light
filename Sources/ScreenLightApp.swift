import SwiftUI
import AppKit

@main
struct ScreenLightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        WindowGroup("ScreenLight") {
            OptionsView()
                .environmentObject(state)
                .frame(width: 380, height: 470)
                .fixedSize()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Remove the "New Window" menu item — this is a single-window utility.
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // If we quit while the light is on, put the brightness back where it was.
        LightController.shared.restoreIfNeeded()
    }
}
