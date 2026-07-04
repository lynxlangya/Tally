import XCTest
@testable import Tally

final class CoreDataBillRepositoryAggregateTests: XCTestCase {
    @MainActor
    func testAggregatesUseActiveBillsOnly() throws {
        let persistence = PersistenceController(inMemory: true, runsStartupSeed: false)
        let repository = CoreDataBillRepository(context: persistence.container.viewContext)

        _ = try repository.create(makeDraft(day: 1))
        _ = try repository.create(makeDraft(day: 2))
        let deleted = try repository.create(makeDraft(day: 2))
        try repository.softDelete(
            id: deleted.id,
            deletedAt: fixedDate(day: 3),
            trashUntil: fixedDate(day: 10)
        )
        _ = try repository.create(makeDraft(day: 2))

        XCTAssertEqual(try repository.count(), 3)
        XCTAssertEqual(try repository.distinctDayCount(), 2)
        XCTAssertEqual(try repository.dayKeyBounds()?.min, "2026-05-01")
        XCTAssertEqual(try repository.dayKeyBounds()?.max, "2026-05-02")
    }

    @MainActor
    func testAggregatesReturnEmptyValuesForEmptyStore() throws {
        let persistence = PersistenceController(inMemory: true, runsStartupSeed: false)
        let repository = CoreDataBillRepository(context: persistence.container.viewContext)

        XCTAssertEqual(try repository.count(), 0)
        XCTAssertEqual(try repository.distinctDayCount(), 0)
        XCTAssertNil(try repository.dayKeyBounds())
    }

    private func makeDraft(day: Int) -> BillDraft {
        BillDraft(
            type: .expense,
            amount: Money(cents: 1_000),
            occurredAtLocal: fixedDate(day: day),
            note: nil,
            categoryId: nil,
            isFromRecurring: false
        )
    }

    private func fixedDate(day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: day,
            hour: 9,
            minute: 0,
            second: 0
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
