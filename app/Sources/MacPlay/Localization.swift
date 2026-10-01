import Foundation

/// UI language: English, French or Indonesian. Follows the system language by default,
/// but the user can force one via the "lang" preference ("system" | "fr" | "en" | "id").
/// Views re-read L.t on every render, and the root view is re-created when the
/// preference changes (see MacPlayApp .id), so switching applies immediately.
enum L {
    enum Language { case en, fr, id }

    static let systemLanguage: Language = {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        return preferred.hasPrefix("fr") ? .fr : preferred.hasPrefix("id") ? .id : .en
    }()

    static var current: Language {
        switch UserDefaults.standard.string(forKey: "lang") {
        case "fr": return .fr
        case "en": return .en
        case "id": return .id
        default: return systemLanguage
        }
    }

    /// Data files have French variants only (notes_fr, fix_fr…); other languages read English.
    static var fr: Bool { current == .fr }

    static func t(_ en: String, _ fr: String, _ id: String) -> String {
        switch current {
        case .en: return en
        case .fr: return fr
        case .id: return id
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, fr, en, id
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return L.t("System", "Système", "Sistem")
        case .fr: return "Français"
        case .en: return "English"
        case .id: return "Bahasa Indonesia"
        }
    }
}
