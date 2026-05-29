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
    static let defaultMoneyDisplaySymbol = MoneyDisplaySymbol.default

    @Published private(set) var selectedLanguage: AppLanguage
    @Published private(set) var selectedMoneyDisplaySymbol: MoneyDisplaySymbol
    let languageOptions = AppLanguage.allCases
    let moneyDisplaySymbolOptions = MoneyDisplaySymbol.allCases

    private let defaults: UserDefaults
    private let systemLocaleProvider: () -> Locale
    private let syncsSharedStores: Bool

    init(
        defaults: UserDefaults = .standard,
        systemLocaleProvider: @escaping () -> Locale = { Locale.autoupdatingCurrent },
        syncsSharedStores: Bool? = nil
    ) {
        self.defaults = defaults
        self.systemLocaleProvider = systemLocaleProvider
        let shouldSyncSharedStores = syncsSharedStores ?? (defaults === UserDefaults.standard)
        self.syncsSharedStores = shouldSyncSharedStores
        let storedValue = defaults.string(forKey: Keys.selectedLanguage)
        let storedMoneySymbol = defaults.string(forKey: Keys.selectedMoneyDisplaySymbol)
            ?? (shouldSyncSharedStores ? MoneyDisplaySymbolStore.loadSelectedSymbol() : nil)
        selectedLanguage = AppLanguage(rawValue: storedValue ?? "") ?? Self.defaultLanguage
        selectedMoneyDisplaySymbol = MoneyDisplaySymbol(rawValue: storedMoneySymbol ?? "") ?? Self.defaultMoneyDisplaySymbol

        if storedValue != selectedLanguage.rawValue || storedMoneySymbol != selectedMoneyDisplaySymbol.rawValue {
            persistAll()
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
        persistLanguage()
    }

    func setMoneyDisplaySymbol(_ symbol: MoneyDisplaySymbol) {
        guard symbol != selectedMoneyDisplaySymbol else { return }
        selectedMoneyDisplaySymbol = symbol
        persistMoneyDisplaySymbol()
    }

    func resetToDefault() {
        setLanguage(Self.defaultLanguage)
    }

    private func persistAll() {
        persistLanguage()
        persistMoneyDisplaySymbol()
    }

    private func persistLanguage() {
        defaults.set(selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
        TallyLanguageStore.saveSelectedLanguage(selectedLanguage.rawValue)
    }

    private func persistMoneyDisplaySymbol() {
        defaults.set(selectedMoneyDisplaySymbol.rawValue, forKey: Keys.selectedMoneyDisplaySymbol)
        if syncsSharedStores {
            MoneyDisplaySymbolStore.saveSelectedSymbol(selectedMoneyDisplaySymbol.rawValue)
        }
    }
}

private enum Keys {
    static let selectedLanguage = "language.selected"
    static let selectedMoneyDisplaySymbol = "money.symbol.selected"
}
