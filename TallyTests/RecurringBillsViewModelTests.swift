import XCTest
@testable import Tally

final class RecurringBillsViewModelTests: XCTestCase {
    func testLoadBuildsSummaryAndDisplayText() async throws {
        let rent = makeCategory(id: UUID(), name: "房租", iconKey: "house.fill", colorHex: 0x4D5E92, type: .expense)
        let salary = makeCategory(id: UUID(), name: "工资", iconKey: "banknote.fill", colorHex: 0x4D7148, type: .income)
        let monthly = makeTask(
            category: rent,
            amountCents: 540000,
            rule: .monthlyFirst,
            nextFireDate: fixedDate(year: 2026, month: 6, day: 1, hour: 9, minute: 0),
            isEnabled: true
        )
        let paused = makeTask(
            category: salary,
            type: .income,
            amountCents: 1200000,
            rule: .weeklyMonday,
            nextFireDate: fixedDate(year: 2026, month: 6, day: 8, hour: 9, minute: 0),
            isEnabled: false
        )

        let result = await MainActor.run { () -> (Int, Int, Int, [String], [String], [Bool]) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [paused, monthly])
            let categoryRepository = MockCategoryRepository(seed: [rent, salary])
            let viewModel = RecurringBillsViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository
            )
            viewModel.load()
            return (
                viewModel.enabledCount,
                viewModel.pausedCount,
                viewModel.monthlyFixedExpenseCents,
                viewModel.items.map(\.ruleText),
                viewModel.items.map(\.nextFireText),
                viewModel.items.map(\.isEnabled)
            )
        }

        XCTAssertEqual(result.0, 1)
        XCTAssertEqual(result.1, 1)
        XCTAssertEqual(result.2, 540000)
        XCTAssertEqual(result.3, ["月初", "每周"])
        XCTAssertEqual(result.4, ["6/1 周一", "6/8 周一"])
        XCTAssertEqual(result.5, [true, false])
    }

    func testToggleEnabledPersistsAndReloadsCounts() async throws {
        let category = makeCategory(id: UUID(), name: "房租", iconKey: "house.fill", colorHex: nil, type: .expense)
        let task = makeTask(
            category: category,
            amountCents: 540000,
            rule: .monthlyFirst,
            nextFireDate: fixedDate(year: 2026, month: 6, day: 1, hour: 9, minute: 0),
            isEnabled: true
        )

        let result = await MainActor.run { () -> (Bool, Int, Int) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [task])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillsViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository
            )
            viewModel.load()
            viewModel.toggleEnabled(id: task.id, isEnabled: false)
            return (
                recurringRepository.tasks.first?.isEnabled ?? true,
                viewModel.enabledCount,
                viewModel.pausedCount
            )
        }

        XCTAssertFalse(result.0)
        XCTAssertEqual(result.1, 0)
        XCTAssertEqual(result.2, 1)
    }

    func testLoadFailureSurfacesErrorAndKeepsExistingRows() async throws {
        let category = makeCategory(id: UUID(), name: "房租", iconKey: "house.fill", colorHex: nil, type: .expense)
        let task = makeTask(
            category: category,
            amountCents: 540000,
            rule: .monthlyFirst,
            nextFireDate: fixedDate(year: 2026, month: 6, day: 1, hour: 9, minute: 0),
            isEnabled: true
        )

        let result = await MainActor.run { () -> (Int, Int, String?) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [task])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillsViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository
            )
            viewModel.load()
            recurringRepository.listError = RepositoryError.notFound
            viewModel.load()
            return (viewModel.items.count, viewModel.enabledCount, viewModel.errorMessage)
        }

        XCTAssertEqual(result.0, 1)
        XCTAssertEqual(result.1, 1)
        XCTAssertEqual(result.2, "定时账单加载失败，请稍后重试")
    }

    func testToggleFailureSurfacesErrorAndKeepsState() async throws {
        let category = makeCategory(id: UUID(), name: "房租", iconKey: "house.fill", colorHex: nil, type: .expense)
        let task = makeTask(
            category: category,
            amountCents: 540000,
            rule: .monthlyFirst,
            nextFireDate: fixedDate(year: 2026, month: 6, day: 1, hour: 9, minute: 0),
            isEnabled: true
        )

        let result = await MainActor.run { () -> (Bool, Int, String?) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [task])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillsViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository
            )
            viewModel.load()
            recurringRepository.setEnabledError = RepositoryError.notFound
            viewModel.toggleEnabled(id: task.id, isEnabled: false)
            return (viewModel.items.first?.isEnabled ?? false, viewModel.enabledCount, viewModel.errorMessage)
        }

        XCTAssertTrue(result.0)
        XCTAssertEqual(result.1, 1)
        XCTAssertEqual(result.2, "暂停定时账单失败，请稍后重试")
    }

    func testDeleteFailureSurfacesErrorAndKeepsState() async throws {
        let category = makeCategory(id: UUID(), name: "房租", iconKey: "house.fill", colorHex: nil, type: .expense)
        let task = makeTask(
            category: category,
            amountCents: 540000,
            rule: .monthlyFirst,
            nextFireDate: fixedDate(year: 2026, month: 6, day: 1, hour: 9, minute: 0),
            isEnabled: true
        )

        let result = await MainActor.run { () -> (Int, String?) in
            let recurringRepository = InMemoryRecurringRepository(tasks: [task])
            let categoryRepository = MockCategoryRepository(seed: [category])
            let viewModel = RecurringBillsViewModel(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository
            )
            viewModel.load()
            recurringRepository.deleteError = RepositoryError.notFound
            viewModel.delete(id: task.id)
            return (viewModel.items.count, viewModel.errorMessage)
        }

        XCTAssertEqual(result.0, 1)
        XCTAssertEqual(result.1, "删除定时账单失败，请稍后重试")
    }

    private func makeCategory(
        id: UUID,
        name: String,
        iconKey: String,
        colorHex: Int?,
        type: BillType
    ) -> CategoryRecord {
        CategoryRecord(
            id: id,
            type: type,
            name: name,
            iconKey: iconKey,
            colorHex: colorHex,
            isSystem: false,
            sortOrder: 1
        )
    }

    private func makeTask(
        category: CategoryRecord,
        type: BillType? = nil,
        amountCents: Int,
        rule: RepeatRule,
        nextFireDate: Date,
        isEnabled: Bool
    ) -> RecurringTaskRecord {
        let firstDate = fixedDate(year: 2026, month: 5, day: 1, hour: 9, minute: 0)
        return RecurringTaskRecord(
            id: UUID(),
            type: type ?? category.type,
            amount: Money(cents: amountCents),
            categoryId: category.id,
            note: nil,
            firstDate: firstDate,
            repeatRule: rule.rawValue,
            nextFireDate: nextFireDate,
            hour: 9,
            minute: 0,
            lastRunAtUTC: nil,
            isEnabled: isEnabled,
            createdAt: firstDate,
            updatedAt: firstDate
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
