import Foundation

enum MoneyDisplaySymbol: String, CaseIterable, Identifiable, Codable {
    case yuan
    case dollar

    static let `default`: MoneyDisplaySymbol = .yuan

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .yuan:
            return "¥"
        case .dollar:
            return "$"
        }
    }

    func displayTitle(locale: Locale) -> String {
        switch self {
        case .yuan:
            return TallyLocalization.text(.moneySymbolYuan, locale: locale)
        case .dollar:
            return TallyLocalization.text(.moneySymbolDollar, locale: locale)
        }
    }

    func displaySubtitle(locale: Locale) -> String {
        switch self {
        case .yuan:
            return TallyLocalization.text(.moneySymbolYuanSubtitle, locale: locale)
        case .dollar:
            return TallyLocalization.text(.moneySymbolDollarSubtitle, locale: locale)
        }
    }
}

enum MoneyDisplaySymbolStore {
    static let selectedSymbolKey = "money.symbol.selected"
    private static let appGroupId = "group.com.langya.Tally"

    static var current: MoneyDisplaySymbol {
        MoneyDisplaySymbol(rawValue: loadSelectedSymbol() ?? "") ?? MoneyDisplaySymbol.default
    }

    static func saveSelectedSymbol(_ rawValue: String) {
        sharedDefaults()?.set(rawValue, forKey: selectedSymbolKey)
    }

    static func loadSelectedSymbol() -> String? {
        sharedDefaults()?.string(forKey: selectedSymbolKey)
    }

    private static func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }
}
