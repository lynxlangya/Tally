import Foundation

struct Money: Equatable, Hashable, Codable {
    let cents: Int

    init(cents: Int) {
        precondition(cents >= 0, "Money cannot be negative.")
        self.cents = cents
    }

    var decimalAmount: Decimal {
        Decimal(cents) / Decimal(100)
    }
}

enum MoneyFormatter {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    static func string(from money: Money) -> String {
        string(fromCents: money.cents)
    }

    static func string(fromCents cents: Int) -> String {
        precondition(cents >= 0, "Money cannot be negative.")
        let amount = Decimal(cents) / Decimal(100)
        let number = NSDecimalNumber(decimal: amount)
        return currencyFormatter.string(from: number) ?? "CNY \(number)"
    }
}
