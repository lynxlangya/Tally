import XCTest
@testable import Tally

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

    func testRunCatchUpPrefetchesOnceAndSkipsExistingRecurringBillsAcrossSixtyDays() throws {
        let now = fixedDate(year: 2026, month: 4, day: 30, hour: 10, minute: 0)
        let firstFireDate = try date(byAddingDays: -59, to: now)
        let categoryId = UUID()
        let amount = Money(cents: 500)
        let note = "早餐"
        let existingBills = try [0, 17, 42].map { offset in
            try makeRecurringBill(
                amount: amount,
                occurredAtLocal: date(byAddingDays: offset, to: firstFireDate),
                note: note,
                categoryId: categoryId,
                createdAt: now
            )
        }
        let recurringRepository = InMemoryRecurringRepository(tasks: [
            makeDailyTask(
                amount: amount,
                categoryId: categoryId,
                note: note,
                nextFireDate: firstFireDate
            )
        ])
        let billRepository = InMemoryBillRepository(records: existingBills)
        let service = DefaultRecurringService(
            recurringRepository: recurringRepository,
            billRepository: billRepository,
            nowProvider: { now }
        )

        let createdCount = try service.runCatchUp(maxDays: 60)

        XCTAssertEqual(createdCount, 57)
        XCTAssertEqual(billRepository.createdDrafts.count, 57)
        XCTAssertEqual(billRepository.records.count, 60)
        XCTAssertEqual(billRepository.listRangeRequests.count, 1)

        let secondCreatedCount = try service.runCatchUp(maxDays: 60)

        XCTAssertEqual(secondCreatedCount, 0)
        XCTAssertEqual(billRepository.createdDrafts.count, 57)
        XCTAssertEqual(billRepository.records.count, 60)
        XCTAssertEqual(billRepository.listRangeRequests.count, 1)
    }

    func testRunCatchUpDoesNotTreatDifferentTaskTimesAsDuplicates() throws {
        let now = fixedDate(year: 2026, month: 2, day: 7, hour: 10, minute: 0)
        let firstFireDate = fixedDate(year: 2026, month: 2, day: 7, hour: 9, minute: 0)
        let secondFireDate = fixedDate(year: 2026, month: 2, day: 7, hour: 10, minute: 0)
        let categoryId = UUID()
        let amount = Money(cents: 800)
        let note = "午餐"
        let recurringRepository = InMemoryRecurringRepository(tasks: [
            makeDailyTask(
                amount: amount,
                categoryId: categoryId,
                note: note,
                nextFireDate: firstFireDate
            ),
            makeDailyTask(
                amount: amount,
                categoryId: categoryId,
                note: note,
                nextFireDate: secondFireDate
            )
        ])
        let billRepository = InMemoryBillRepository()
        let service = DefaultRecurringService(
            recurringRepository: recurringRepository,
            billRepository: billRepository,
            nowProvider: { now }
        )

        let createdCount = try service.runCatchUp(maxDays: 1)

        XCTAssertEqual(createdCount, 2)
        XCTAssertEqual(billRepository.createdDrafts.map(\.occurredAtLocal), [firstFireDate, secondFireDate])
        XCTAssertEqual(billRepository.listRangeRequests.count, 2)
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

    private func date(byAddingDays days: Int, to date: Date) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return try XCTUnwrap(calendar.date(byAdding: .day, value: days, to: date))
    }

    private func makeDailyTask(
        amount: Money,
        categoryId: UUID,
        note: String,
        nextFireDate: Date
    ) -> RecurringTaskRecord {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let components = calendar.dateComponents([.hour, .minute], from: nextFireDate)
        return RecurringTaskRecord(
            id: UUID(),
            type: .expense,
            amount: amount,
            categoryId: categoryId,
            note: note,
            firstDate: nextFireDate,
            repeatRule: RepeatRule.daily.rawValue,
            nextFireDate: nextFireDate,
            hour: components.hour ?? 0,
            minute: components.minute ?? 0,
            lastRunAtUTC: nil,
            isEnabled: true,
            createdAt: nextFireDate,
            updatedAt: nextFireDate
        )
    }

    private func makeRecurringBill(
        amount: Money,
        occurredAtLocal: Date,
        note: String,
        categoryId: UUID,
        createdAt: Date
    ) -> BillRecord {
        let snapshot = TimePolicy.snapshot(for: occurredAtLocal)
        return BillRecord(
            id: UUID(),
            type: .expense,
            amount: amount,
            occurredAtUTC: snapshot.occurredAtUTC,
            tzId: snapshot.tzId,
            tzOffset: snapshot.tzOffset,
            occurredLocalDate: snapshot.occurredLocalDate,
            note: note,
            categoryId: categoryId,
            isFromRecurring: true,
            createdAt: createdAt,
            updatedAt: createdAt,
            deletedAt: nil,
            trashUntil: nil
        )
    }
}
