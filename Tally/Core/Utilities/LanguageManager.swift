import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case zhHans
    case en

    var id: String { rawValue }

    func displayTitle(locale: Locale) -> String {
        switch self {
        case .system: return TallyLocalization.text(.languageSystem, locale: locale)
        case .zhHans: return TallyLocalization.text(.languageSimplifiedChinese, locale: locale)
        case .en: return TallyLocalization.text(.languageEnglish, locale: locale)
        }
    }

    var nativeName: String {
        switch self {
        case .system: return TallyLocalization.text(.languageSystemNative)
        case .zhHans: return "简体中文"
        case .en: return "English"
        }
    }

    func displaySubtitle(locale: Locale) -> String {
        switch self {
        case .system: return TallyLocalization.text(.languageSystemSubtitle, locale: locale)
        case .zhHans: return TallyLocalization.text(.languageSimplifiedChineseSubtitle, locale: locale)
        case .en: return TallyLocalization.text(.languageEnglishSubtitle, locale: locale)
        }
    }

    var shortCode: String {
        switch self {
        case .system: return TallyLocalization.text(.languageSystemCode, locale: LanguageManager.shared.currentLocale)
        case .zhHans: return TallyLocalization.text(.languageSimplifiedChineseCode, locale: LanguageManager.shared.currentLocale)
        case .en: return TallyLocalization.text(.languageEnglishCode, locale: LanguageManager.shared.currentLocale)
        }
    }

    func sampleTitle(locale: Locale) -> String {
        TallyLocalization.text(.today, locale: locale)
    }

    func sampleSubtitle(locale: Locale) -> String {
        TallyLocalization.text(.monthlyExpense, locale: locale)
    }

    var localeIdentifier: String {
        switch self {
        case .system: return resolvedSystemLanguage.localeIdentifier
        case .zhHans: return "zh-Hans-CN"
        case .en: return "en-US"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    private var resolvedSystemLanguage: AppLanguage {
        Self.supportedContentLanguage(for: Locale.autoupdatingCurrent)
    }

    static func supportedContentLanguage(for locale: Locale) -> AppLanguage {
        if locale.language.languageCode?.identifier == "en" {
            return .en
        }
        return .zhHans
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    static let defaultLanguage: AppLanguage = .system

    @Published private(set) var selectedLanguage: AppLanguage
    let languageOptions = AppLanguage.allCases

    private let defaults: UserDefaults
    private let systemLocaleProvider: () -> Locale

    init(defaults: UserDefaults = .standard, systemLocaleProvider: @escaping () -> Locale = { Locale.autoupdatingCurrent }) {
        self.defaults = defaults
        self.systemLocaleProvider = systemLocaleProvider
        let storedValue = defaults.string(forKey: Keys.selectedLanguage)
        selectedLanguage = AppLanguage(rawValue: storedValue ?? "") ?? Self.defaultLanguage

        if storedValue != selectedLanguage.rawValue {
            persist()
        }
    }

    var currentLocale: Locale {
        selectedLanguage == .system ? effectiveLanguage.locale : selectedLanguage.locale
    }

    var effectiveLanguage: AppLanguage {
        selectedLanguage == .system
            ? AppLanguage.supportedContentLanguage(for: systemLocaleProvider())
            : selectedLanguage
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != selectedLanguage else { return }
        selectedLanguage = language
        persist()
    }

    func resetToDefault() {
        setLanguage(Self.defaultLanguage)
    }

    private func persist() {
        defaults.set(selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
        TallyLanguageStore.saveSelectedLanguage(selectedLanguage.rawValue)
    }
}

private enum Keys {
    static let selectedLanguage = "language.selected"
}
