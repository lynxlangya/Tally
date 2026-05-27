import XCTest
@testable import Tally

final class BillsListViewModelTests: XCTestCase {
    func testMonthlySummaryTrendAndRankingUseActiveRange() async throws {
        let anchor = fixedDate(year: 2026, month: 5, day: 20)
        let foodId = UUID()
        let travelId = UUID()
        let salaryId = UUID()

        let result = await MainActor.run { () -> (BillsListViewModel.Summary, [Int], [BillsListViewModel.RankingItem], [String], Int, Int) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2026, month: 5, day: 1), categoryId: foodId),
                    makeBill(type: .expense, cents: 2_000, date: fixedDate(year: 2026, month: 5, day: 15), categoryId: foodId),
                    makeBill(type: .expense, cents: 3_000, date: fixedDate(year: 2026, month: 5, day: 20), categoryId: travelId),
                    makeBill(type: .income, cents: 10_000, date: fixedDate(year: 2026, month: 5, day: 5), categoryId: salaryId),
                    makeBill(type: .expense, cents: 9_000, date: fixedDate(year: 2026, month: 4, day: 30), categoryId: foodId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: foodId, type: .expense, name: "餐饮", icon: "fork.knife", colorHex: 0xB8553E),
                    makeCategory(id: travelId, type: .expense, name: "旅行", icon: "airplane", colorHex: 0x3D7D7E),
                    makeCategory(id: salaryId, type: .income, name: "薪资", icon: "banknote.fill", colorHex: 0x4D7148)
                ])
            )
            viewModel.anchorDate = anchor
            viewModel.timeRange = .month
            viewModel.selectedType = .expense
            viewModel.load()
            return (
                viewModel.summary,
                viewModel.trend30Cents,
                viewModel.categoryRanking,
                viewModel.axisLabels,
                viewModel.dayKeys.count,
                viewModel.categoryRankingTotalCount
            )
        }

        XCTAssertEqual(result.0.expenseCents, 6_000)
        XCTAssertEqual(result.0.incomeCents, 10_000)
        XCTAssertEqual(result.1.count, 31)
        XCTAssertEqual(result.1[0], 1_000)
        XCTAssertEqual(result.1[14], 2_000)
        XCTAssertEqual(result.1[19], 3_000)
        XCTAssertEqual(result.2.map(\.title), ["餐饮", "旅行"])
        XCTAssertEqual(result.2.map(\.count), [2, 1])
        XCTAssertEqual(result.2.first?.iconColorHex, 0xB8553E)
        XCTAssertEqual(result.3, ["5/1", "5/15", "5/31"])
        XCTAssertEqual(result.4, 4)
        XCTAssertEqual(result.5, 2)
    }

    func testQuarterAndYearRangesProduceSensibleTrendPointCounts() async throws {
        let categoryId = UUID()
        let result = await MainActor.run { () -> (Int, Int, String, String) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2026, month: 1, day: 3), categoryId: categoryId),
                    makeBill(type: .expense, cents: 2_000, date: fixedDate(year: 2026, month: 3, day: 28), categoryId: categoryId),
                    makeBill(type: .expense, cents: 3_000, date: fixedDate(year: 2026, month: 8, day: 8), categoryId: categoryId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: categoryId, type: .expense, name: "日用", icon: "cart.fill", colorHex: 0x4D7148)
                ])
            )
            viewModel.anchorDate = fixedDate(year: 2026, month: 2, day: 10)
            viewModel.timeRange = .quarter
            viewModel.selectedType = .expense
            viewModel.load()
            let quarterCount = viewModel.trend30Cents.count
            let quarterTitle = viewModel.timeTitle

            viewModel.anchorDate = fixedDate(year: 2026, month: 8, day: 10)
            viewModel.timeRange = .year
            let yearCount = viewModel.trend30Cents.count
            let yearTitle = viewModel.timeTitle
            return (quarterCount, yearCount, quarterTitle, yearTitle)
        }

        XCTAssertEqual(result.0, 13)
        XCTAssertEqual(result.1, 12)
        XCTAssertEqual(result.2, "2026 · Q1")
        XCTAssertEqual(result.3, "2026 · 全年")
    }

    func testCustomRangeUsesTrailingThirtyDaysAndKeepsAllBillRows() async throws {
        let expenseId = UUID()
        let incomeId = UUID()

        let result = await MainActor.run { () -> ([Int], [String], [String]) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2026, month: 5, day: 1), categoryId: expenseId),
                    makeBill(type: .expense, cents: 2_000, date: fixedDate(year: 2026, month: 5, day: 20), categoryId: expenseId),
                    makeBill(type: .income, cents: 5_000, date: fixedDate(year: 2026, month: 5, day: 20), categoryId: incomeId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: expenseId, type: .expense, name: "购物", icon: "cart.fill", colorHex: 0x4D7148),
                    makeCategory(id: incomeId, type: .income, name: "奖金", icon: "gift.fill", colorHex: 0xA65566)
                ])
            )
            viewModel.anchorDate = fixedDate(year: 2026, month: 5, day: 20)
            viewModel.timeRange = .custom
            viewModel.load()
            return (viewModel.trend30Cents, viewModel.axisLabels, viewModel.dayKeys)
        }

        XCTAssertEqual(result.0.count, 30)
        XCTAssertEqual(result.0.first, 0)
        XCTAssertEqual(result.0[10], 1_000)
        XCTAssertEqual(result.0.last, 2_000)
        XCTAssertEqual(result.1, ["4/21", "5/5", "5/20"])
        XCTAssertEqual(result.2, ["2026-05-20", "2026-05-01"])
    }

    private func makeCategory(id: UUID, type: BillType, name: String, icon: String, colorHex: Int) -> CategoryRecord {
        CategoryRecord(
            id: id,
            type: type,
            name: name,
            iconKey: icon,
            colorHex: colorHex,
            isSystem: false,
            sortOrder: 0
        )
    }

    private func makeBill(type: BillType, cents: Int, date: Date, categoryId: UUID) -> BillRecord {
        let snapshot = TimePolicy.snapshot(for: date, timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current)
        return BillRecord(
            id: UUID(),
            type: type,
            amount: Money(cents: cents),
            occurredAtUTC: snapshot.occurredAtUTC,
            tzId: snapshot.tzId,
            tzOffset: snapshot.tzOffset,
            occurredLocalDate: snapshot.occurredLocalDate,
            note: nil,
            categoryId: categoryId,
            isFromRecurring: false,
            createdAt: date,
            updatedAt: date,
            deletedAt: nil,
            trashUntil: nil
        )
    }

    private func fixedDate(year: Int, month: Int, day: Int) -> Date {
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
