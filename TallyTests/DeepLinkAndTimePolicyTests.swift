import XCTest
@testable import Tally

final class DeepLinkAndTimePolicyTests: XCTestCase {
    func testDeepLinkRouterParsesKnownRoutes() {
        XCTAssertEqual(DeepLinkRouter.parse(URL(string: "tally://quickEntry")!), .quickEntry)
        XCTAssertEqual(DeepLinkRouter.parse(URL(string: "tally://home")!), .home)
        XCTAssertEqual(DeepLinkRouter.parse(URL(string: "tally://statistics")!), .statistics)
    }

    func testDeepLinkRouterRejectsUnknownRouteOrScheme() {
        XCTAssertNil(DeepLinkRouter.parse(URL(string: "tally://unknown")!))
        XCTAssertNil(DeepLinkRouter.parse(URL(string: "https://quickEntry")!))
    }

    func testEditorDatePreservesOriginalLocalComponentsAcrossTimeZone() {
        let sourceTimeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let displayTimeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current

        var sourceCalendar = Calendar(identifier: .gregorian)
        sourceCalendar.timeZone = sourceTimeZone
        let sourceDate = sourceCalendar.date(from: DateComponents(
            year: 2026,
            month: 2,
            day: 7,
            hour: 9,
            minute: 30,
            second: 0
        )) ?? Date(timeIntervalSince1970: 0)

        let editorDate = TimePolicy.editorDate(
            from: sourceDate,
            tzId: sourceTimeZone.identifier,
            tzOffset: sourceTimeZone.secondsFromGMT(for: sourceDate),
            displayTimeZone: displayTimeZone
        )

        var displayCalendar = Calendar(identifier: .gregorian)
        displayCalendar.timeZone = displayTimeZone
        let components = displayCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: editorDate)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 7)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 30)
    }

    func testBillTimeFormatterUsesStoredTimeZoneMetadata() {
        let timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let occurredAtUTC = calendar.date(from: DateComponents(
            year: 2026,
            month: 2,
            day: 7,
            hour: 21,
            minute: 5,
            second: 0
        )) ?? Date(timeIntervalSince1970: 0)

        let text = BillTimeFormatter.timeText(
            from: occurredAtUTC,
            tzId: timeZone.identifier,
            tzOffset: timeZone.secondsFromGMT(for: occurredAtUTC)
        )

        XCTAssertEqual(text, "21:05")
    }
}
