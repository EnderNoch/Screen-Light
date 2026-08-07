import SwiftUI
import Combine
import AppKit

/// Shared, observable settings for the Options screen.
/// All properties are persisted in UserDefaults and restored on next launch.
final class AppState: ObservableObject {
    static let shared = AppState()

    /// Target backlight brightness, 0...100.
    @Published var brightness: Double {
        didSet { UserDefaults.standard.set(brightness, forKey: "brightness") }
    }

    /// Fill-light color.
    @Published var color: Color {
        didSet { AppState.saveColor(color) }
    }

    /// UI language.
    @Published var lang: Lang {
        didSet { UserDefaults.standard.set(lang.rawValue, forKey: "lang") }
    }

    private init() {
        let ud = UserDefaults.standard
        brightness = ud.object(forKey: "brightness") != nil ? ud.double(forKey: "brightness") : 80
        if let raw = ud.string(forKey: "lang"), let l = Lang(rawValue: raw) {
            lang = l
        } else {
            lang = .system
        }
        color = AppState.loadColor() ?? .white
    }

    private static func saveColor(_ color: Color) {
        guard let ns = NSColor(color).usingColorSpace(.sRGB) else { return }
        let ud = UserDefaults.standard
        ud.set(Double(ns.redComponent),   forKey: "colorR")
        ud.set(Double(ns.greenComponent), forKey: "colorG")
        ud.set(Double(ns.blueComponent),  forKey: "colorB")
        ud.set(true, forKey: "colorSaved")
    }

    private static func loadColor() -> Color? {
        let ud = UserDefaults.standard
        guard ud.bool(forKey: "colorSaved") else { return nil }
        return Color(red:   ud.double(forKey: "colorR"),
                     green: ud.double(forKey: "colorG"),
                     blue:  ud.double(forKey: "colorB"))
    }
}
