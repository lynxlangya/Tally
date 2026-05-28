import Foundation

enum MoneyFormatter {
    struct Parts: Equatable {
        let integer: String
        let decimal: String
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let centFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.minimumIntegerDigits = 2
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    private static let compactWanFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    static func string(fromCents cents: Int) -> String {
        precondition(cents >= 0, "Money cannot be negative.")
        let amount = Decimal(cents) / Decimal(100)
        let number = NSDecimalNumber(decimal: amount)
        return currencyFormatter.string(from: number) ?? "CNY \(number)"
    }

    static func wholeYuanString(fromCents cents: Int) -> String {
        precondition(cents >= 0, "Money cannot be negative.")
        let yuan = cents / 100
        let amount = integerFormatter.string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        return "¥\(amount)"
    }

    static func compactString(fromCents cents: Int) -> String {
        let sign = cents < 0 ? "-" : ""
        let absCents = abs(cents)
        let yuan = absCents / 100

        if yuan >= 10_000 {
            let value = Decimal(yuan) / Decimal(10_000)
            let number = NSDecimalNumber(decimal: value)
            let amount = compactWanFormatter.string(from: number) ?? "\(number)"
            return "\(sign)¥\(amount)万"
        }

        return "\(sign)\(wholeYuanString(fromCents: absCents))"
    }

    static func parts(fromCents cents: Int) -> Parts {
        precondition(cents >= 0, "Money cannot be negative.")
        let yuan = cents / 100
        let cent = cents % 100
        let integer = integerFormatter.string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        let decimal = centFormatter.string(from: NSNumber(value: cent)) ?? (cent < 10 ? "0\(cent)" : "\(cent)")
        return Parts(integer: integer, decimal: decimal)
    }
}
