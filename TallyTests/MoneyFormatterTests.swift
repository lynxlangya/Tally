import XCTest
@testable import Tally

final class MoneyFormatterTests: XCTestCase {
    func testCurrencyStringUsesCNYWithTwoFractionDigits() {
        XCTAssertEqual(MoneyFormatter.string(fromCents: 642_188), "¥6,421.88")
        XCTAssertEqual(MoneyFormatter.string(from: Money(cents: 33_00)), "¥33.00")
    }

    func testPartsUseGroupedIntegerAndTwoDigitDecimal() {
        let parts = MoneyFormatter.parts(fromCents: 642_105)

        XCTAssertEqual(parts.integer, "6,421")
        XCTAssertEqual(parts.decimal, "05")
    }

    func testWholeYuanStringDropsCentsAndKeepsGrouping() {
        XCTAssertEqual(MoneyFormatter.wholeYuanString(fromCents: 642_188), "¥6,421")
    }

    func testCompactStringSupportsSignedWidgetAmounts() {
        XCTAssertEqual(MoneyFormatter.compactString(fromCents: -987_600), "-¥9,876")
        XCTAssertEqual(MoneyFormatter.compactString(fromCents: 12_345_678), "¥12.3万")
    }
}
