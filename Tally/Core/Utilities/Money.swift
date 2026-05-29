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

extension MoneyFormatter {
    static func string(
        from money: Money,
        locale: Locale = TallyLocalization.defaultLocale,
        symbol: MoneyDisplaySymbol = MoneyDisplaySymbolStore.current
    ) -> String {
        string(fromCents: money.cents, locale: locale, symbol: symbol)
    }
}
