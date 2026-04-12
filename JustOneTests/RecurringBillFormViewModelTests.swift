import XCTest
@testable import JustOne

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
