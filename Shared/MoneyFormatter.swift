import Foundation

enum MoneyFormatter {
    struct Parts: Equatable {
        let integer: String
        let decimal: String
    }

    private static func integerFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }

    private static func centFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumIntegerDigits = 2
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter
    }

    private static func compactWanFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = false
        return formatter
    }

    static func string(
        fromCents cents: Int,
        locale: Locale = TallyLocalization.defaultLocale,
        symbol: MoneyDisplaySymbol = MoneyDisplaySymbolStore.current
    ) -> String {
        precondition(cents >= 0, "Money cannot be negative.")
        let parts = parts(fromCents: cents, locale: locale)
        return "\(currencySymbol(symbol: symbol))\(parts.integer).\(parts.decimal)"
    }

    static func wholeYuanString(
        fromCents cents: Int,
        locale: Locale = TallyLocalization.defaultLocale,
        symbol: MoneyDisplaySymbol = MoneyDisplaySymbolStore.current
    ) -> String {
        precondition(cents >= 0, "Money cannot be negative.")
        let yuan = cents / 100
        let amount = integerFormatter(locale: locale).string(from: NSNumber(value: yuan)) ?? "\(yuan)"
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
            let amount = compactWanFormatter(locale: locale).string(from: number) ?? "\(number)"
            if TallyLocalization.supportedLanguageCode(for: locale) == "en" {
                let thousandValue = Decimal(yuan) / Decimal(1_000)
                let thousandNumber = NSDecimalNumber(decimal: thousandValue)
                let thousandAmount = compactWanFormatter(locale: locale).string(from: thousandNumber) ?? "\(thousandNumber)"
                return "\(sign)\(currencySymbol(symbol: symbol))\(thousandAmount)k"
            }
            return "\(sign)\(currencySymbol(symbol: symbol))\(amount)万"
        }

        return "\(sign)\(wholeYuanString(fromCents: absCents, locale: locale, symbol: symbol))"
    }

    static func parts(fromCents cents: Int, locale: Locale = TallyLocalization.defaultLocale) -> Parts {
        precondition(cents >= 0, "Money cannot be negative.")
        let yuan = cents / 100
        let cent = cents % 100
        let integer = integerFormatter(locale: locale).string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        let decimal = centFormatter(locale: locale).string(from: NSNumber(value: cent)) ?? (cent < 10 ? "0\(cent)" : "\(cent)")
        return Parts(integer: integer, decimal: decimal)
    }

    static func currencySymbol(symbol: MoneyDisplaySymbol = MoneyDisplaySymbolStore.current) -> String {
        symbol.symbol
    }

    static func displaySymbol(from symbolText: String) -> MoneyDisplaySymbol {
        MoneyDisplaySymbol.allCases.first { $0.symbol == symbolText } ?? .default
    }
}
