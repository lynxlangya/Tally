import XCTest
@testable import Tally

final class RecurringBillFormViewModelTests: XCTestCase {
    func testSaveAllowsTodayFutureTime() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let category = makeCategory()
        let firstExecution = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 30)

        let result = await MainActor.run { () -> (Bool, Int, Date?, Date?, Int?, Int?) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillFormViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                nowProvider: { now }
            )
            viewModel.selectCategory(category)
            viewModel.amountText = "12.34"
            viewModel.firstDate = firstExecution
            let didSave = viewModel.save()
            let createdTask = recurringRepository.tasks.first
            return (
                didSave,
                recurringRepository.tasks.count,
                createdTask?.firstDate,
                createdTask?.nextFireDate,
                createdTask?.hour,
                createdTask?.minute
            )
        }

        XCTAssertTrue(result.0)
        XCTAssertEqual(result.1, 1)
        XCTAssertEqual(result.2, firstExecution)
        XCTAssertEqual(result.3, firstExecution)
        XCTAssertEqual(result.4, 10)
        XCTAssertEqual(result.5, 30)
    }

    func testSaveRejectsTodayPastTime() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let category = makeCategory()
        let pastExecution = fixedDate(year: 2026, month: 4, day: 12, hour: 9, minute: 30)

        let result = await MainActor.run { () -> (Bool, String?, Int) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillFormViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                nowProvider: { now }
            )
            viewModel.selectCategory(category)
            viewModel.amountText = "12.34"
            viewModel.firstDate = pastExecution
            return (viewModel.save(), viewModel.errorMessage, recurringRepository.tasks.count)
        }

        XCTAssertFalse(result.0)
        XCTAssertEqual(result.1, "首次执行时间必须晚于当前时间")
        XCTAssertEqual(result.2, 0)
    }

    func testSaveUsesTomorrowTimeAsNextFireDate() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let category = makeCategory()
        let firstExecution = fixedDate(year: 2026, month: 4, day: 13, hour: 8, minute: 15)

        let result = await MainActor.run { () -> (Bool, Int, Date?, Date?, Int?, Int?) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillFormViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                nowProvider: { now }
            )
            viewModel.selectCategory(category)
            viewModel.amountText = "12.34"
            viewModel.firstDate = firstExecution
            let didSave = viewModel.save()
            let createdTask = recurringRepository.tasks.first
            return (
                didSave,
                recurringRepository.tasks.count,
                createdTask?.firstDate,
                createdTask?.nextFireDate,
                createdTask?.hour,
                createdTask?.minute
            )
        }

        XCTAssertTrue(result.0)
        XCTAssertEqual(result.1, 1)
        XCTAssertEqual(result.2, firstExecution)
        XCTAssertEqual(result.3, firstExecution)
        XCTAssertEqual(result.4, 8)
        XCTAssertEqual(result.5, 15)
    }


    func testSaveEditingTaskUsesUpdateAndPreservesIdentity() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let category = makeCategory()
        let existing = makeTask(
            id: UUID(),
            category: category,
            amountCents: 1200,
            firstDate: fixedDate(year: 2026, month: 4, day: 13, hour: 8, minute: 0),
            rule: .daily,
            now: now
        )

        let result = await MainActor.run { () -> (Bool, Int, UUID?, Int?, String?, RepeatRule?) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [existing])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillFormViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                existingTask: existing,
                nowProvider: { now }
            )
            viewModel.loadCategories()
            viewModel.amountText = "45.67"
            viewModel.note = "  新备注  "
            viewModel.repeatRule = .monthlyLast
            let didSave = viewModel.save()
            let updated = recurringRepository.updatedTasks.first
            return (
                didSave,
                recurringRepository.updatedTasks.count,
                updated?.id,
                updated?.amount.cents,
                updated?.note,
                updated.flatMap { RepeatRule(rawValue: $0.repeatRule) }
            )
        }

        XCTAssertTrue(result.0)
        XCTAssertEqual(result.1, 1)
        XCTAssertEqual(result.2, existing.id)
        XCTAssertEqual(result.3, 4567)
        XCTAssertEqual(result.4, "新备注")
        XCTAssertEqual(result.5, .monthlyLast)
    }

    func testWeeklySelectionMapsToWeeklyMonday() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let category = makeCategory()
        let firstExecution = fixedDate(year: 2026, month: 4, day: 13, hour: 8, minute: 15)

        let result = await MainActor.run { () -> String? in
            let recurringRepository = InMemoryRecurringRepository(tasks: [])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillFormViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                nowProvider: { now }
            )
            viewModel.selectCategory(category)
            viewModel.amountText = "12.34"
            viewModel.firstDate = firstExecution
            viewModel.repeatRule = .weeklyMonday
            _ = viewModel.save()
            return recurringRepository.tasks.first?.repeatRule
        }

        XCTAssertEqual(result, RepeatRule.weeklyMonday.rawValue)
    }


    func testMonthlyFirstRuleSelectionMovesFirstDateToUpcomingMonthStart() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let category = makeCategory()

        let result = await MainActor.run { () -> (Date, String) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillFormViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                nowProvider: { now }
            )
            viewModel.selectRepeatRule(.monthlyFirst)
            return (viewModel.firstDate, viewModel.nextFireText)
        }

        XCTAssertEqual(result.0, fixedDate(year: 2026, month: 5, day: 1, hour: 11, minute: 0))
        XCTAssertEqual(result.1, "5/1 周五")
    }

    func testMonthlyLastRuleSelectionMovesFirstDateToUpcomingMonthEnd() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let category = makeCategory()

        let result = await MainActor.run { () -> (Date, String) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillFormViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                nowProvider: { now }
            )
            viewModel.selectRepeatRule(.monthlyLast)
            return (viewModel.firstDate, viewModel.nextFireText)
        }

        XCTAssertEqual(result.0, fixedDate(year: 2026, month: 4, day: 30, hour: 11, minute: 0))
        XCTAssertEqual(result.1, "4/30 周四")
    }


    func testDailyRuleSelectionResetsFirstDateToUpcomingHour() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let category = makeCategory()

        let result = await MainActor.run { () -> (Date, String) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillFormViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                nowProvider: { now }
            )
            viewModel.selectRepeatRule(.monthlyFirst)
            viewModel.selectRepeatRule(.daily)
            return (viewModel.firstDate, viewModel.nextFireText)
        }

        XCTAssertEqual(result.0, fixedDate(year: 2026, month: 4, day: 12, hour: 11, minute: 0))
        XCTAssertEqual(result.1, "4/12 周日")
    }

    private func makeCategory() -> CategoryRecord {
        CategoryRecord(
            id: UUID(),
            type: .expense,
            name: "午餐",
            iconKey: "fork.knife",
            colorHex: nil,
            isSystem: false,
            sortOrder: 0
        )
    }


    private func makeTask(
        id: UUID,
        category: CategoryRecord,
        amountCents: Int,
        firstDate: Date,
        rule: RepeatRule,
        now: Date
    ) -> RecurringTaskRecord {
        RecurringTaskRecord(
            id: id,
            type: category.type,
            amount: Money(cents: amountCents),
            categoryId: category.id,
            note: "旧备注",
            firstDate: firstDate,
            repeatRule: rule.rawValue,
            nextFireDate: firstDate,
            hour: 8,
            minute: 0,
            lastRunAtUTC: nil,
            isEnabled: true,
            createdAt: now,
            updatedAt: now
        )
    }

    private func fixedDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
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
