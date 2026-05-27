import XCTest
@testable import Tally

final class WidgetSnapshotTests: XCTestCase {
    func testWidgetSnapshotRoundTripsNewFields() throws {
        let snapshot = WidgetSnapshot(
            updatedAt: Date(timeIntervalSince1970: 1_779_873_600),
            quickEntry: QuickEntryWidgetModel(
                todayExpenseCents: 12_300,
                todayEntryCount: 4,
                yesterdayExpenseCents: 24_600,
                currencySymbol: "¥"
            ),
            summary: SummaryTrendWidgetModel(
                monthExpenseCents: 90_000,
                monthIncomeCents: 150_000,
                monthBalanceCents: 60_000,
                sparkline: [0.1, 0.4, 1.0],
                trend7: [0, 0.2, 0.4, 0.1, 1.0, 0.6, 0.3],
                monthNumber: 5,
                average7Cents: 7_700
            )
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)

        XCTAssertEqual(decoded.quickEntry.todayEntryCount, 4)
        XCTAssertEqual(decoded.quickEntry.yesterdayExpenseCents, 24_600)
        XCTAssertEqual(decoded.summary.trend7, [0, 0.2, 0.4, 0.1, 1.0, 0.6, 0.3])
        XCTAssertEqual(decoded.summary.monthNumber, 5)
        XCTAssertEqual(decoded.summary.average7Cents, 7_700)
    }

    func testWidgetSnapshotDecodesLegacyPayloadWithDefaults() throws {
        let legacyPayload = """
        {
          "quickEntry": {
            "todayExpenseCents": 12300,
            "currencySymbol": "¥"
          },
          "summary": {
            "monthExpenseCents": 90000,
            "monthIncomeCents": 150000,
            "monthBalanceCents": 60000,
            "sparkline": [0.1, 0.4, 1.0]
          }
        }
        """

        let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: Data(legacyPayload.utf8))

        XCTAssertEqual(decoded.quickEntry.todayExpenseCents, 12_300)
        XCTAssertEqual(decoded.quickEntry.todayEntryCount, 0)
        XCTAssertNil(decoded.quickEntry.yesterdayExpenseCents)
        XCTAssertEqual(decoded.summary.trend7, [0.1, 0.4, 1.0])
        XCTAssertEqual(decoded.summary.average7Cents, 0)
    }

    func testWidgetSnapshotRefreshIncludesPreviousMonthForSevenDayTrend() throws {
        let repository = InMemoryBillRepository(records: [
            makeBill(dayKey: "2026-04-29", cents: 1_000, type: .expense),
            makeBill(dayKey: "2026-04-30", cents: 2_000, type: .expense),
            makeBill(dayKey: "2026-05-01", cents: 3_000, type: .expense),
            makeBill(dayKey: "2026-05-01", cents: 5_000, type: .income)
        ])
        let originalSnapshot = WidgetDataStore.loadSnapshot()
        defer { WidgetDataStore.saveSnapshot(originalSnapshot) }

        WidgetSnapshotService.refresh(using: repository, now: fixedDate(year: 2026, month: 5, day: 1))
        let snapshot = WidgetDataStore.loadSnapshot()

        XCTAssertEqual(snapshot.quickEntry.todayExpenseCents, 3_000)
        XCTAssertEqual(snapshot.quickEntry.todayEntryCount, 1)
        XCTAssertEqual(snapshot.quickEntry.yesterdayExpenseCents, 2_000)
        XCTAssertEqual(snapshot.summary.monthExpenseCents, 3_000)
        XCTAssertEqual(snapshot.summary.monthIncomeCents, 5_000)
        XCTAssertEqual(snapshot.summary.monthBalanceCents, 2_000)
        XCTAssertEqual(snapshot.summary.monthNumber, 5)
        XCTAssertEqual(snapshot.summary.average7Cents, 857)
        XCTAssertEqual(snapshot.summary.trend7, [0, 0, 0, 0, 1.0 / 3.0, 2.0 / 3.0, 1.0])
    }
}

private extension WidgetSnapshotTests {
    func makeBill(dayKey: String, cents: Int, type: BillType) -> BillRecord {
        let date = DayKeyFormatter.date(from: dayKey, timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current) ?? Date()
        return BillRecord(
            id: UUID(),
            type: type,
            amount: Money(cents: cents),
            occurredAtUTC: date,
            tzId: "Asia/Shanghai",
            tzOffset: 28_800,
            occurredLocalDate: dayKey,
            note: nil,
            categoryId: UUID(),
            isFromRecurring: false,
            createdAt: date,
            updatedAt: date,
            deletedAt: nil,
            trashUntil: nil
        )
    }

    func fixedDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: 12,
            minute: 0,
            second: 0
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
