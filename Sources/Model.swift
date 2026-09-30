import SwiftUI
import ServiceManagement


/// Every setting of the app, saved in UserDefaults as soon as it changes.
@Observable
final class Model {
    static let shared = Model()

    @ObservationIgnored private let ud = UserDefaults.standard
    /// Opens the options window; set by any view that has `openWindow`.
    @ObservationIgnored var openMain: (() -> Void)?

    /// Backlight while the light is on, 0...100.
    var brightness: Double { didSet { ud.set(brightness, forKey: "brightness"); Light.shared.refresh() } }
    var color: Color { didSet { ud.set(color.hex, forKey: "color") } }
    /// Edge light thickness as a share of the screen's shorter side.
    var edgeWidth: Double { didSet { ud.set(edgeWidth, forKey: "edgeWidth") } }
    var photoBooth: Bool { didSet { ud.set(photoBooth, forKey: "photoBooth"); PhotoBooth.check() } }

    /// Accent from System Settings → Appearance → Color, as sRGB; nil for Multicolor,
    /// which keeps Prosty Timer's violet.
    private(set) var accent = Model.readAccent()


    /// The name in the system's language, from the bundle's localized Info.plist (build.sh).
    static let appName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
        ?? Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Screen Light"

    static let swatches = ["#FFFFFF", "#FFE2B8", "#FFD2DC", "#D8E8FF"]

    private init() {
        brightness = ud.object(forKey: "brightness") as? Double ?? 80
        color = Color(hex: ud.string(forKey: "color") ?? "") ?? .white
        edgeWidth = ud.object(forKey: "edgeWidth") as? Double ?? 0.12
        photoBooth = ud.object(forKey: "photoBooth") as? Bool ?? true
    }

    /// The system's language, as in any Mac app; a per-app choice in System Settings →
    /// General → Language & Region → Applications counts too.
    var activeLang: String { Strings.detected }
    var s: Strings { Strings.for(activeLang) }

    /// Hooks that need NSApp; called once the app has launched.
    func start() {
        // Opens at login from the first launch on. Only once: taking it out in System
        // Settings → General → Login Items stays that way.
        if !ud.bool(forKey: "loginSetUp") {
            try? SMAppService.mainApp.register()
            ud.set(true, forKey: "loginSetUp")
        }
        // System Settings writes these to the global domain; key-value observing hears the
        // write the moment it happens, so a new color arrives as fast as the system shows it.
        watcher = DefaultsWatcher(keys: ["AppleAccentColor", "AppleHighlightColor"]) {
            Model.shared.refreshAccent()
        }
        // AppKit may still hold the old accent at that instant; it says when it has the new one.
        NotificationCenter.default.addObserver(
            forName: NSColor.systemColorsDidChangeNotification, object: nil, queue: .main
        ) { _ in MainActor.assumeIsolated { Model.shared.refreshAccent() } }
    }

    @ObservationIgnored private var watcher: DefaultsWatcher?

    private func refreshAccent() {
        let a = Model.readAccent()
        if a != accent { accent = a }
    }

    /// Multicolor leaves AppleAccentColor unset.
    private static func readAccent() -> SIMD3<Double>? {
        guard UserDefaults.standard.object(forKey: "AppleAccentColor") != nil,
              let c = NSColor.controlAccentColor.usingColorSpace(.sRGB) else { return nil }
        return [Double(c.redComponent), Double(c.greenComponent), Double(c.blueComponent)]
    }

}

/// Calls back on the main thread whenever one of the given defaults changes, in this
/// process or any other.
nonisolated final class DefaultsWatcher: NSObject {
    private let keys: [String]
    private let onChange: @MainActor () -> Void

    init(keys: [String], onChange: @escaping @MainActor () -> Void) {
        self.keys = keys
        self.onChange = onChange
        super.init()
        keys.forEach { UserDefaults.standard.addObserver(self, forKeyPath: $0, options: [], context: nil) }
    }

    deinit {
        keys.forEach { UserDefaults.standard.removeObserver(self, forKeyPath: $0) }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let onChange = onChange
        DispatchQueue.main.async { MainActor.assumeIsolated { onChange() } }
    }
}

extension Color {
    init?(hex: String) {
        guard hex.count == 7, hex.first == "#", let v = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        self.init(red: Double(v >> 16 & 0xFF) / 255, green: Double(v >> 8 & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }

    var hex: String {
        let c = NSColor(self).usingColorSpace(.sRGB) ?? .white
        let byte = { (x: CGFloat) in Int((min(max(x, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(c.redComponent), byte(c.greenComponent), byte(c.blueComponent))
    }
}
