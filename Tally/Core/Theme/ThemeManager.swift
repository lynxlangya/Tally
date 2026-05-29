import Combine
import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case dark
    case light
    case system

    var id: String { rawValue }

    var title: String {
        let locale = LanguageManager.shared.currentLocale
        switch self {
        case .dark:
            return TallyLocalization.text("appearance_dark_title", locale: locale)
        case .light:
            return TallyLocalization.text("appearance_light_title", locale: locale)
        case .system:
            return TallyLocalization.text("appearance_system_title", locale: locale)
        }
    }

    var subtitle: String {
        let locale = LanguageManager.shared.currentLocale
        switch self {
        case .dark:
            return TallyLocalization.text("appearance_dark_subtitle", locale: locale)
        case .light:
            return TallyLocalization.text("appearance_light_subtitle", locale: locale)
        case .system:
            return TallyLocalization.text("appearance_system_subtitle", locale: locale)
        }
    }

    var profileTitle: String {
        let locale = LanguageManager.shared.currentLocale
        switch self {
        case .dark:
            return TallyLocalization.text("appearance_dark_profile", locale: locale)
        case .light:
            return TallyLocalization.text("appearance_light_profile", locale: locale)
        case .system:
            return TallyLocalization.text("appearance_system_profile", locale: locale)
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        case .system:
            return nil
        }
    }
}

enum ThemeAppIconOption: String, CaseIterable, Identifiable {
    case vermilion
    case moon
    case ink
    case inkNote

    var id: String { rawValue }

    var title: String {
        let locale = LanguageManager.shared.currentLocale
        switch self {
        case .vermilion:
            return TallyLocalization.text("app_icon_vermilion", locale: locale)
        case .moon:
            return TallyLocalization.text("app_icon_moon", locale: locale)
        case .ink:
            return TallyLocalization.text("app_icon_ink", locale: locale)
        case .inkNote:
            return TallyLocalization.text("app_icon_ink_note", locale: locale)
        }
    }

    var alternateIconName: String? {
        switch self {
        case .vermilion:
            return nil
        case .moon:
            return "AppIconMoon"
        case .ink:
            return "AppIconInk"
        case .inkNote:
            return "AppIconInkNote"
        }
    }
}

struct AccentOption: Identifiable {
    let id: String
    let color: Color
    let name: String
    let englishName: String
    let hex: UInt32

    var displayName: String {
        "\(localizedName) · \(englishName)"
    }

    var localizedName: String {
        TallyLocalization.text("accent_\(id.snakeCased)", locale: LanguageManager.shared.currentLocale)
    }

    var hexText: String {
        String(format: "#%06X", hex)
    }

    var foregroundColor: Color {
        id == "moon" ? .black.opacity(0.82) : .tallyAccentInk
    }

    static func == (lhs: AccentOption, rhs: AccentOption) -> Bool {
        lhs.id == rhs.id
    }
}

extension AccentOption: Equatable {}

struct ThemeSettings: Equatable {
    var appearance: AppearanceMode
    var accent: AccentOption
    var appIcon: ThemeAppIconOption
    var reduceMotion: Bool
    var hapticFeedback: Bool
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    static let defaultAppearance: AppearanceMode = .dark
    static let defaultAccentId = "vermilion"
    static let defaultAppIcon: ThemeAppIconOption = .vermilion

    @Published private(set) var settings: ThemeSettings
    let accentOptions: [AccentOption]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.accentOptions = [
            AccentOption(id: "vermilion", color: Self.color(hex: 0xC84A38), name: "朱砂", englishName: "Vermilion", hex: 0xC84A38),
            AccentOption(id: "redOchre", color: Self.color(hex: 0xA83C2D), name: "赭石", englishName: "Red Ochre", hex: 0xA83C2D),
            AccentOption(id: "pine", color: Self.color(hex: 0x1E5B55), name: "松绿", englishName: "Pine", hex: 0x1E5B55),
            AccentOption(id: "brass", color: Self.color(hex: 0xB89253), name: "黄铜", englishName: "Brass", hex: 0xB89253),
            AccentOption(id: "wisteria", color: Self.color(hex: 0x6F5C93), name: "紫藤", englishName: "Wisteria", hex: 0x6F5C93),
            AccentOption(id: "moon", color: Self.color(hex: 0xE6DFCF), name: "月白", englishName: "Moon", hex: 0xE6DFCF)
        ]

        let fallbackAccent = accentOptions.first { $0.id == Self.defaultAccentId } ?? accentOptions[0]
        let appearance = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? Self.defaultAppearance
        let accent = accentOptions.first { $0.id == defaults.string(forKey: Keys.accent) } ?? fallbackAccent
        let appIcon = ThemeAppIconOption(rawValue: defaults.string(forKey: Keys.appIcon) ?? "") ?? Self.defaultAppIcon

        self.settings = ThemeSettings(
            appearance: appearance,
            accent: accent,
            appIcon: appIcon,
            reduceMotion: defaults.bool(forKey: Keys.reduceMotion),
            hapticFeedback: defaults.object(forKey: Keys.hapticFeedback) == nil ? true : defaults.bool(forKey: Keys.hapticFeedback)
        )
    }

    var defaultAccent: AccentOption {
        accentOptions.first { $0.id == Self.defaultAccentId } ?? accentOptions[0]
    }

    func setAppearance(_ mode: AppearanceMode) {
        update { $0.appearance = mode }
    }

    func setAccent(_ accent: AccentOption) {
        update { $0.accent = accent }
    }

    func setAppIcon(_ icon: ThemeAppIconOption) {
        update { $0.appIcon = icon }
    }

    func setReduceMotion(_ enabled: Bool) {
        update { $0.reduceMotion = enabled }
    }

    func setHapticFeedback(_ enabled: Bool) {
        update { $0.hapticFeedback = enabled }
    }

    func resetToDefaults() {
        settings = ThemeSettings(
            appearance: Self.defaultAppearance,
            accent: defaultAccent,
            appIcon: Self.defaultAppIcon,
            reduceMotion: false,
            hapticFeedback: true
        )
        persist()
    }

    private func update(_ mutate: (inout ThemeSettings) -> Void) {
        var next = settings
        mutate(&next)
        guard next != settings else { return }
        settings = next
        persist()
    }

    private func persist() {
        defaults.set(settings.appearance.rawValue, forKey: Keys.appearance)
        defaults.set(settings.accent.id, forKey: Keys.accent)
        defaults.set(settings.appIcon.rawValue, forKey: Keys.appIcon)
        defaults.set(settings.reduceMotion, forKey: Keys.reduceMotion)
        defaults.set(settings.hapticFeedback, forKey: Keys.hapticFeedback)
    }

    private static func color(hex: UInt32) -> Color {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

private enum Keys {
    static let appearance = "theme.appearance"
    static let accent = "theme.accent"
    static let appIcon = "theme.appIcon"
    static let reduceMotion = "theme.reduceMotion"
    static let hapticFeedback = "theme.hapticFeedback"
}

private extension String {
    var snakeCased: String {
        unicodeScalars.reduce(into: "") { result, scalar in
            let character = Character(scalar)
            if CharacterSet.uppercaseLetters.contains(scalar), !result.isEmpty {
                result.append("_")
                result.append(String(character).lowercased())
            } else {
                result.append(String(character))
            }
        }
    }
}
