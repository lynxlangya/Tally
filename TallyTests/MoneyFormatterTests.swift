import XCTest
@testable import Tally

final class MoneyFormatterTests: XCTestCase {
    func testCurrencyStringUsesSelectedDisplaySymbolWithTwoFractionDigits() {
        XCTAssertEqual(MoneyFormatter.string(fromCents: 642_188, symbol: .yuan), "¥6,421.88")
        XCTAssertEqual(MoneyFormatter.string(fromCents: 642_188, symbol: .dollar), "$6,421.88")
        XCTAssertEqual(MoneyFormatter.string(from: Money(cents: 33_00), symbol: .yuan), "¥33.00")
    }

    func testPartsUseGroupedIntegerAndTwoDigitDecimal() {
        let parts = MoneyFormatter.parts(fromCents: 642_105)

        XCTAssertEqual(parts.integer, "6,421")
        XCTAssertEqual(parts.decimal, "05")
    }

    func testWholeYuanStringDropsCentsAndKeepsGrouping() {
        XCTAssertEqual(MoneyFormatter.wholeYuanString(fromCents: 642_188, symbol: .yuan), "¥6,421")
        XCTAssertEqual(MoneyFormatter.wholeYuanString(fromCents: 642_188, symbol: .dollar), "$6,421")
    }

    func testCompactStringSupportsSignedWidgetAmounts() {
        XCTAssertEqual(MoneyFormatter.compactString(fromCents: -987_600, symbol: .yuan), "-¥9,876")
        XCTAssertEqual(MoneyFormatter.compactString(fromCents: 12_345_678, symbol: .yuan), "¥12.3万")
        XCTAssertEqual(MoneyFormatter.compactString(fromCents: 12_345_678, locale: Locale(identifier: "en-US"), symbol: .dollar), "$123.5k")
    }
}
