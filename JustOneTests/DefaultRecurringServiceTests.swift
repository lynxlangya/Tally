import XCTest
@testable import JustOne

final class DefaultRecurringServiceTests: XCTestCase {
    func testRunCatchUpCreatesBillAndAdvancesNextFireDate() throws {
        let now = fixedDate(year: 2026, month: 2, day: 7, hour: 9, minute: 59)
        let dueDate = fixedDate(year: 2026, month: 2, day: 6, hour: 10, minute: 0)
        let recurringRepository = InMemoryRecurringRepository(tasks: [
            RecurringTaskRecord(
                id: UUID(),
                type: .expense,
                amount: Money(cents: 1234),
                categoryId: UUID(),
                note: "咖啡",
                firstDate: dueDate,
                repeatRule: RepeatRule.daily.rawValue,
                nextFireDate: dueDate,
                hour: 10,
                minute: 0,
                lastRunAtUTC: nil,
                isEnabled: true,
                createdAt: dueDate,
                updatedAt: dueDate
            )
        ])
        let billRepository = InMemoryBillRepository()
        let service = DefaultRecurringService(
            recurringRepository: recurringRepository,
            billRepository: billRepository,
            nowProvider: { now }
        )

        let createdCount = try service.runCatchUp(maxDays: 30)

        XCTAssertEqual(createdCount, 1)
        XCTAssertEqual(billRepository.createdDrafts.count, 1)
        let updated = try XCTUnwrap(recurringRepository.updatedTasks.first)
        XCTAssertGreaterThan(updated.nextFireDate, now)
        XCTAssertEqual(updated.lastRunAtUTC, now)
    }

    func testRunCatchUpSkipsWhenRecurringBillAlreadyExists() throws {
        let now = fixedDate(year: 2026, month: 2, day: 7, hour: 9, minute: 59)
        let dueDate = fixedDate(year: 2026, month: 2, day: 6, hour: 10, minute: 0)
        let categoryId = UUID()
        let snapshot = TimePolicy.snapshot(for: dueDate)
        let duplicateBill = BillRecord(
            id: UUID(),
            type: .expense,
            amount: Money(cents: 500),
            occurredAtUTC: snapshot.occurredAtUTC,
            tzId: snapshot.tzId,
            tzOffset: snapshot.tzOffset,
            occurredLocalDate: snapshot.occurredLocalDate,
            note: "午餐",
            categoryId: categoryId,
            isFromRecurring: true,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            trashUntil: nil
        )

        let recurringRepository = InMemoryRecurringRepository(tasks: [
            RecurringTaskRecord(
                id: UUID(),
                type: .expense,
                amount: Money(cents: 500),
                categoryId: categoryId,
                note: "午餐",
                firstDate: dueDate,
                repeatRule: RepeatRule.daily.rawValue,
                nextFireDate: dueDate,
                hour: 10,
                minute: 0,
                lastRunAtUTC: nil,
                isEnabled: true,
                createdAt: dueDate,
                updatedAt: dueDate
            )
        ])
        let billRepository = InMemoryBillRepository(records: [duplicateBill])
        let service = DefaultRecurringService(
            recurringRepository: recurringRepository,
            billRepository: billRepository,
            nowProvider: { now }
        )

        let createdCount = try service.runCatchUp(maxDays: 30)

        XCTAssertEqual(createdCount, 0)
        XCTAssertEqual(billRepository.createdDrafts.count, 0)
        XCTAssertEqual(recurringRepository.updatedTasks.count, 1)
    }

    private func fixedDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: 0
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
