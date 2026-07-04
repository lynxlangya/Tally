import Foundation
import os

enum MoneyFormatter {
    struct Parts: Equatable {
        let integer: String
        let decimal: String
    }

    private static let logger = Logger(subsystem: "com.langya.Tally", category: "money")
    private static let threadDictionaryKey = "tally.money.formatter.storage"

    private enum FormatterKind: String {
        case integer
        case cent
        case compactWan
    }

    static func string(
        fromCents cents: Int,
        locale: Locale = TallyLocalization.defaultLocale,
        symbol: MoneyDisplaySymbol = MoneyDisplaySymbolStore.current
    ) -> String {
        let safeCents = safeDisplayCents(cents)
        let parts = parts(fromCents: safeCents, locale: locale)
        return "\(currencySymbol(symbol: symbol))\(parts.integer).\(parts.decimal)"
    }

    static func wholeYuanString(
        fromCents cents: Int,
        locale: Locale = TallyLocalization.defaultLocale,
        symbol: MoneyDisplaySymbol = MoneyDisplaySymbolStore.current
    ) -> String {
        let safeCents = safeDisplayCents(cents)
        let yuan = safeCents / 100
        let amount = cachedFormatter(.integer, locale: locale).string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        return "\(currencySymbol(symbol: symbol))\(amount)"
    }

    static func compactString(
        fromCents cents: Int,
        locale: Locale = TallyLocalization.defaultLocale,
        symbol: MoneyDisplaySymbol = MoneyDisplaySymbolStore.current
    ) -> String {
        let sign = cents < 0 ? "-" : ""
        let absCents = abs(cents)
        let yuan = absCents / 100

        if yuan >= 10_000 {
            let value = Decimal(yuan) / Decimal(10_000)
            let number = NSDecimalNumber(decimal: value)
            let amount = cachedFormatter(.compactWan, locale: locale).string(from: number) ?? "\(number)"
            if TallyLocalization.supportedLanguageCode(for: locale) == "en" {
                let thousandValue = Decimal(yuan) / Decimal(1_000)
                let thousandNumber = NSDecimalNumber(decimal: thousandValue)
                let thousandAmount = cachedFormatter(.compactWan, locale: locale).string(from: thousandNumber) ?? "\(thousandNumber)"
                return "\(sign)\(currencySymbol(symbol: symbol))\(thousandAmount)k"
            }
            return "\(sign)\(currencySymbol(symbol: symbol))\(amount)万"
        }

        return "\(sign)\(wholeYuanString(fromCents: absCents, locale: locale, symbol: symbol))"
    }

    static func parts(fromCents cents: Int, locale: Locale = TallyLocalization.defaultLocale) -> Parts {
        let safeCents = safeDisplayCents(cents)
        let yuan = safeCents / 100
        let cent = safeCents % 100
        let integer = cachedFormatter(.integer, locale: locale).string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        let decimal = cachedFormatter(.cent, locale: locale).string(from: NSNumber(value: cent)) ?? (cent < 10 ? "0\(cent)" : "\(cent)")
        return Parts(integer: integer, decimal: decimal)
    }

    static func currencySymbol(symbol: MoneyDisplaySymbol = MoneyDisplaySymbolStore.current) -> String {
        symbol.symbol
    }

    static func displaySymbol(from symbolText: String) -> MoneyDisplaySymbol {
        MoneyDisplaySymbol.allCases.first { $0.symbol == symbolText } ?? .default
    }

    private static func safeDisplayCents(_ cents: Int) -> Int {
        guard cents >= 0 else {
            logger.fault("MoneyFormatter received negative cents: \(cents, privacy: .public)")
            return 0
        }
        return cents
    }

    private static func cachedFormatter(_ kind: FormatterKind, locale: Locale) -> NumberFormatter {
        let threadDictionary = Thread.current.threadDictionary
        let storage: NSMutableDictionary
        if let existing = threadDictionary[threadDictionaryKey] as? NSMutableDictionary {
            storage = existing
        } else {
            let created = NSMutableDictionary()
            threadDictionary[threadDictionaryKey] = created
            storage = created
        }

        let cacheKey = "\(kind.rawValue)|\(locale.identifier)"
        if let formatter = storage[cacheKey] as? NumberFormatter {
            return formatter
        }

        let formatter = makeFormatter(kind, locale: locale)
        storage[cacheKey] = formatter
        return formatter
    }

    private static func makeFormatter(_ kind: FormatterKind, locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale

        switch kind {
        case .integer:
            formatter.maximumFractionDigits = 0
            formatter.usesGroupingSeparator = true
        case .cent:
            formatter.minimumIntegerDigits = 2
            formatter.maximumFractionDigits = 0
            formatter.usesGroupingSeparator = false
        case .compactWan:
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
            formatter.usesGroupingSeparator = false
        }

        return formatter
    }
}
