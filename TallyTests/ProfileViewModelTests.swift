import XCTest
@testable import Tally

final class ProfileViewModelTests: XCTestCase {
    func testLoadBuildsProfileMetricsFromRepositories() async throws {
        let now = fixedDate(year: 2026, month: 5, day: 27, hour: 12, minute: 0)
        let monday = fixedDate(year: 2026, month: 5, day: 25, hour: 9, minute: 0)
        let wednesdayMorning = fixedDate(year: 2026, month: 5, day: 27, hour: 8, minute: 0)
        let wednesdayNoon = fixedDate(year: 2026, month: 5, day: 27, hour: 12, minute: 0)
        let lastWeek = fixedDate(year: 2026, month: 5, day: 20, hour: 8, minute: 0)
        let recurringNext = fixedDate(year: 2026, month: 6, day: 1, hour: 9, minute: 0)

        let expenseCategory = makeCategory(type: .expense)
        let incomeCategory = makeCategory(type: .income)

        let result = await MainActor.run { () -> (Int, Int, Int, Int, Int, String?, Set<String>, [Int], [Bool]) in
            let billRepository = InMemoryBillRepository(records: [
                makeBill(date: monday, type: .expense),
                makeBill(date: wednesdayMorning, type: .expense),
                makeBill(date: wednesdayNoon, type: .income),
                makeBill(date: lastWeek, type: .expense)
            ])
            let categoryRepository = MockCategoryRepository(seed: [expenseCategory, incomeCategory])
            let recurringRepository = InMemoryRecurringRepository(tasks: [
                makeRecurring(date: recurringNext, isEnabled: true),
                makeRecurring(date: fixedDate(year: 2026, month: 5, day: 30, hour: 9, minute: 0), isEnabled: false)
            ])
            let viewModel = ProfileViewModel(
                billRepository: billRepository,
                categoryRepository: categoryRepository,
                recurringRepository: recurringRepository,
                calendar: fixedCalendar(),
                nowProvider: { now }
            )

            viewModel.load()

            return (
                viewModel.billCount,
                viewModel.recordedDayCount,
                viewModel.expenseCategoryCount,
                viewModel.incomeCategoryCount,
                viewModel.enabledRecurringCount,
                viewModel.nextRecurringChip,
                viewModel.recordedDayKeysThisWeek,
                viewModel.streakDays.map(\.count),
                viewModel.streakDays.map(\.isFuture)
            )
        }

        XCTAssertEqual(result.0, 4)
        XCTAssertEqual(result.1, 3)
        XCTAssertEqual(result.2, 1)
        XCTAssertEqual(result.3, 1)
        XCTAssertEqual(result.4, 1)
        XCTAssertEqual(result.5, "6月1日")
        XCTAssertEqual(result.6, ["2026-05-25", "2026-05-27"])
        XCTAssertEqual(result.7, [1, 0, 2, 0, 0, 0, 0])
        XCTAssertEqual(result.8, [false, false, false, true, true, true, true])
    }

    private func makeCategory(type: BillType) -> CategoryRecord {
        CategoryRecord(
            id: UUID(),
            type: type,
            name: type == .expense ? "餐饮" : "工资",
            iconKey: type == .expense ? "fork.knife" : "banknote.fill",
            colorHex: nil,
            isSystem: false,
            sortOrder: 1
        )
    }

    private func makeBill(date: Date, type: BillType) -> BillRecord {
        let snapshot = TimePolicy.snapshot(for: date, timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current)
        return BillRecord(
            id: UUID(),
            type: type,
            amount: Money(cents: 1000),
            occurredAtUTC: snapshot.occurredAtUTC,
            tzId: snapshot.tzId,
            tzOffset: snapshot.tzOffset,
            occurredLocalDate: snapshot.occurredLocalDate,
            note: nil,
            categoryId: UUID(),
            isFromRecurring: false,
            createdAt: date,
            updatedAt: date,
            deletedAt: nil,
            trashUntil: nil
        )
    }

    private func makeRecurring(date: Date, isEnabled: Bool) -> RecurringTaskRecord {
        RecurringTaskRecord(
            id: UUID(),
            type: .expense,
            amount: Money(cents: 1000),
            categoryId: UUID(),
            note: nil,
            firstDate: date,
            repeatRule: RepeatRule.monthlyFirst.rawValue,
            nextFireDate: date,
            hour: 9,
            minute: 0,
            lastRunAtUTC: nil,
            isEnabled: isEnabled,
            createdAt: date,
            updatedAt: date
        )
    }

    private func fixedCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return calendar
    }

    private func fixedDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        let calendar = fixedCalendar()
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
