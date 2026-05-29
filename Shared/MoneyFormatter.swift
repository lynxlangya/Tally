import Foundation

enum MoneyFormatter {
    struct Parts: Equatable {
        let integer: String
        let decimal: String
    }

    private static func currencyFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = locale
        return formatter
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

    static func string(fromCents cents: Int, locale: Locale = TallyLocalization.defaultLocale) -> String {
        precondition(cents >= 0, "Money cannot be negative.")
        let amount = Decimal(cents) / Decimal(100)
        let number = NSDecimalNumber(decimal: amount)
        return currencyFormatter(locale: locale).string(from: number) ?? "CNY \(number)"
    }

    static func wholeYuanString(fromCents cents: Int, locale: Locale = TallyLocalization.defaultLocale) -> String {
        precondition(cents >= 0, "Money cannot be negative.")
        let yuan = cents / 100
        let amount = integerFormatter(locale: locale).string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        let symbol = currencySymbol(locale: locale)
        return TallyLocalization.supportedLanguageCode(for: locale) == "en" ? "\(symbol)\(amount)" : "\(symbol)\(amount)"
    }

    static func compactString(fromCents cents: Int, locale: Locale = TallyLocalization.defaultLocale) -> String {
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
                return "\(sign)\(currencySymbol(locale: locale))\(thousandAmount)k"
            }
            return "\(sign)\(currencySymbol(locale: locale))\(amount)万"
        }

        return "\(sign)\(wholeYuanString(fromCents: absCents, locale: locale))"
    }

    static func parts(fromCents cents: Int, locale: Locale = TallyLocalization.defaultLocale) -> Parts {
        precondition(cents >= 0, "Money cannot be negative.")
        let yuan = cents / 100
        let cent = cents % 100
        let integer = integerFormatter(locale: locale).string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        let decimal = centFormatter(locale: locale).string(from: NSNumber(value: cent)) ?? (cent < 10 ? "0\(cent)" : "\(cent)")
        return Parts(integer: integer, decimal: decimal)
    }

    static func currencySymbol(locale: Locale = TallyLocalization.defaultLocale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.locale = locale
        return formatter.currencySymbol ?? "¥"
    }
}
