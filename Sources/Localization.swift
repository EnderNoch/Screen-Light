import Foundation

/// The two UI languages, switched with a segmented control in the options screen.
enum Lang: String, CaseIterable, Identifiable {
    case en, pl

    var id: String { rawValue }
    var short: String { self == .en ? "EN" : "PL" }

    /// Default to Polish if the system language is Polish, otherwise English.
    static var system: Lang {
        (Locale.current.language.languageCode?.identifier == "pl") ? .pl : .en
    }
}

/// All user-facing strings for one language.
struct Strings {
    let lang: Lang

    var subtitle: String   { lang == .pl ? "Lampa doświetlająca" : "Fill light" }
    var brightness: String { lang == .pl ? "Jasność" : "Brightness" }
    var color: String      { lang == .pl ? "Kolor" : "Color" }
    var white: String      { lang == .pl ? "Biały" : "White" }
    var light: String      { lang == .pl ? "Światło" : "Light" }
    var hint: String {
        lang == .pl
            ? "Naciśnij dowolny klawisz lub dotknij gładzika, aby wrócić."
            : "Press any key or tap the trackpad to return."
    }
}
