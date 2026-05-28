import XCTest
@testable import Tally

final class HomeViewModelTests: XCTestCase {
    func testDeleteBillRemovesItemFromGroupsAndRepository() async throws {
        let today = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let categoryId = UUID()
        let result = await MainActor.run { () -> (Int, Bool, Int) in
            let bill = makeBill(
                id: UUID(),
                categoryId: categoryId,
                occurredAtUTC: today,
                occurredLocalDate: "2026-04-12"
            )
            let categoryRepository = MockCategoryRepository(seed: [
                CategoryRecord(
                    id: categoryId,
                    type: .expense,
                    name: "午餐",
                    iconKey: "fork.knife",
                    colorHex: nil,
                    isSystem: false,
                    sortOrder: 0
                )
            ])
            let repository = MockBillRepository(seed: [bill])
            let viewModel = HomeViewModel(
                repository: repository,
                categoryRepository: categoryRepository,
                nowProvider: { today }
            )
            viewModel.load()
            let groupsAfterLoad = viewModel.groups.count
            viewModel.deleteBill(id: bill.id)
            return (groupsAfterLoad, viewModel.groups.isEmpty, (try? repository.list().count) ?? -1)
        }

        XCTAssertEqual(result.0, 1)
        XCTAssertTrue(result.1)
        XCTAssertEqual(result.2, 0)
    }

    func testLoadFailureSurfacesErrorWithoutClearingExistingRows() async throws {
        let today = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let categoryId = UUID()
        let result = await MainActor.run { () -> (Int, String?) in
            let bill = makeBill(
                id: UUID(),
                categoryId: categoryId,
                occurredAtUTC: today,
                occurredLocalDate: "2026-04-12"
            )
            let repository = InMemoryBillRepository(records: [bill])
            let viewModel = HomeViewModel(
                repository: repository,
                categoryRepository: makeCategoryRepository(categoryId: categoryId),
                nowProvider: { today }
            )
            viewModel.load()
            repository.listError = RepositoryError.notFound
            viewModel.load()
            return (viewModel.groups.count, viewModel.errorMessage)
        }

        XCTAssertEqual(result.0, 1)
        XCTAssertEqual(result.1, "账单加载失败，请稍后重试")
    }

    func testDeleteFailureSurfacesErrorAndKeepsRows() async throws {
        let today = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let categoryId = UUID()
        let result = await MainActor.run { () -> (Int, Int, String?) in
            let bill = makeBill(
                id: UUID(),
                categoryId: categoryId,
                occurredAtUTC: today,
                occurredLocalDate: "2026-04-12"
            )
            let repository = InMemoryBillRepository(records: [bill])
            let viewModel = HomeViewModel(
                repository: repository,
                categoryRepository: makeCategoryRepository(categoryId: categoryId),
                nowProvider: { today }
            )
            viewModel.load()
            repository.deleteError = RepositoryError.notFound
            viewModel.deleteBill(id: bill.id)
            return (viewModel.groups.count, (try? repository.list().count) ?? -1, viewModel.errorMessage)
        }

        XCTAssertEqual(result.0, 1)
        XCTAssertEqual(result.1, 1)
        XCTAssertEqual(result.2, "删除账单失败，请稍后重试")
    }

    func testGroupsSortByOccurredLocalDateDescending() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 13, hour: 9, minute: 0)
        let categoryId = UUID()
        let nextDayBill = makeBill(
            id: UUID(),
            categoryId: categoryId,
            occurredAtUTC: fixedDate(year: 2026, month: 4, day: 12, hour: 15, minute: 0),
            occurredLocalDate: "2026-04-13"
        )
        let sameUtcLaterBill = makeBill(
            id: UUID(),
            categoryId: categoryId,
            occurredAtUTC: fixedDate(year: 2026, month: 4, day: 12, hour: 18, minute: 0),
            occurredLocalDate: "2026-04-12"
        )

        let groupIds = await MainActor.run { () -> [String] in
            let categoryRepository = MockCategoryRepository(seed: [
                CategoryRecord(
                    id: categoryId,
                    type: .expense,
                    name: "午餐",
                    iconKey: "fork.knife",
                    colorHex: nil,
                    isSystem: false,
                    sortOrder: 0
                )
            ])
            let repository = MockBillRepository(seed: [sameUtcLaterBill, nextDayBill])
            let viewModel = HomeViewModel(
                repository: repository,
                categoryRepository: categoryRepository,
                nowProvider: { now }
            )
            viewModel.load()
            return viewModel.groups.map(\.id)
        }

        XCTAssertEqual(groupIds, ["2026-04-13", "2026-04-12"])
    }

    func testDailyAverageUsesElapsedDaysInCurrentMonth() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 10, hour: 9, minute: 0)
        let categoryId = UUID()
        let result = await MainActor.run { () -> Int in
            let bills = [
                makeBill(
                    id: UUID(),
                    categoryId: categoryId,
                    amountCents: 1_000,
                    occurredAtUTC: fixedDate(year: 2026, month: 4, day: 1, hour: 9, minute: 0),
                    occurredLocalDate: "2026-04-01"
                ),
                makeBill(
                    id: UUID(),
                    categoryId: categoryId,
                    amountCents: 2_000,
                    occurredAtUTC: fixedDate(year: 2026, month: 4, day: 8, hour: 9, minute: 0),
                    occurredLocalDate: "2026-04-08"
                )
            ]
            let viewModel = makeViewModel(bills: bills, categoryId: categoryId, now: now)
            viewModel.load()
            return viewModel.dailyAverageCents
        }

        XCTAssertEqual(result, 300)
    }

    func testTrend7CentsIncludesOnlyExpensesEndingToday() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 10, hour: 9, minute: 0)
        let categoryId = UUID()
        let result = await MainActor.run { () -> [Int] in
            let bills = [
                makeBill(
                    id: UUID(),
                    categoryId: categoryId,
                    amountCents: 100,
                    occurredAtUTC: fixedDate(year: 2026, month: 4, day: 4, hour: 9, minute: 0),
                    occurredLocalDate: "2026-04-04"
                ),
                makeBill(
                    id: UUID(),
                    categoryId: categoryId,
                    amountCents: 300,
                    occurredAtUTC: fixedDate(year: 2026, month: 4, day: 10, hour: 9, minute: 0),
                    occurredLocalDate: "2026-04-10"
                ),
                makeBill(
                    id: UUID(),
                    categoryId: categoryId,
                    type: .income,
                    amountCents: 900,
                    occurredAtUTC: fixedDate(year: 2026, month: 4, day: 10, hour: 10, minute: 0),
                    occurredLocalDate: "2026-04-10"
                ),
                makeBill(
                    id: UUID(),
                    categoryId: categoryId,
                    amountCents: 500,
                    occurredAtUTC: fixedDate(year: 2026, month: 4, day: 3, hour: 9, minute: 0),
                    occurredLocalDate: "2026-04-03"
                )
            ]
            let viewModel = makeViewModel(bills: bills, categoryId: categoryId, now: now)
            viewModel.load()
            return viewModel.trend7Cents
        }

        XCTAssertEqual(result, [100, 0, 0, 0, 0, 0, 300])
    }

    func testTrend7LabelsUseChineseWeekdayNames() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 10, hour: 9, minute: 0)
        let categoryId = UUID()
        let result = await MainActor.run { () -> ([String], String) in
            let viewModel = makeViewModel(bills: [], categoryId: categoryId, now: now)
            viewModel.load()
            return (viewModel.trend7Labels, viewModel.currentWeekdayText)
        }

        XCTAssertEqual(result.0, ["周六", "周日", "周一", "周二", "周三", "周四", "周五"])
        XCTAssertEqual(result.1, "周五")
    }

    func testItemTitlePrefersNoteAndSubtitleUsesCategoryAndTime() async throws {
        let now = fixedDate(year: 2026, month: 4, day: 10, hour: 9, minute: 0)
        let categoryId = UUID()
        let result = await MainActor.run { () -> (String, String?) in
            let bill = makeBill(
                id: UUID(),
                categoryId: categoryId,
                occurredAtUTC: now,
                occurredLocalDate: "2026-04-10"
            )
            let viewModel = makeViewModel(bills: [bill], categoryId: categoryId, now: now)
            viewModel.load()
            let item = viewModel.groups.first?.items.first
            return (item?.title ?? "", item?.subtitle)
        }

        XCTAssertEqual(result.0, "测试")
        XCTAssertTrue(result.1?.hasPrefix("午餐 · ") == true)
    }

    private func makeBill(
        id: UUID,
        categoryId: UUID,
        type: BillType = .expense,
        amountCents: Int = 1234,
        occurredAtUTC: Date,
        occurredLocalDate: String
    ) -> BillRecord {
        BillRecord(
            id: id,
            type: type,
            amount: Money(cents: amountCents),
            occurredAtUTC: occurredAtUTC,
            tzId: "Asia/Shanghai",
            tzOffset: 28_800,
            occurredLocalDate: occurredLocalDate,
            note: "测试",
            categoryId: categoryId,
            isFromRecurring: false,
            createdAt: occurredAtUTC,
            updatedAt: occurredAtUTC,
            deletedAt: nil,
            trashUntil: nil
        )
    }

    @MainActor
    private func makeViewModel(
        bills: [BillRecord],
        categoryId: UUID,
        now: Date
    ) -> HomeViewModel {
        let categoryRepository = MockCategoryRepository(seed: [
            makeCategory(id: categoryId)
        ])
        let repository = MockBillRepository(seed: bills)
        return HomeViewModel(
            repository: repository,
            categoryRepository: categoryRepository,
            nowProvider: { now }
        )
    }

    private func makeCategoryRepository(categoryId: UUID) -> MockCategoryRepository {
        MockCategoryRepository(seed: [makeCategory(id: categoryId)])
    }

    private func makeCategory(id: UUID) -> CategoryRecord {
        CategoryRecord(
            id: id,
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
