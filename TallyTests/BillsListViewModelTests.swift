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

    func testYearRangeProducesMonthlyTrendPointCounts() async throws {
        let categoryId = UUID()
        let result = await MainActor.run { () -> (Int, String) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2026, month: 1, day: 3), categoryId: categoryId),
                    makeBill(type: .expense, cents: 2_000, date: fixedDate(year: 2026, month: 3, day: 28), categoryId: categoryId),
                    makeBill(type: .expense, cents: 3_000, date: fixedDate(year: 2026, month: 8, day: 8), categoryId: categoryId),
                    makeBill(type: .expense, cents: 4_000, date: fixedDate(year: 2026, month: 9, day: 30), categoryId: categoryId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: categoryId, type: .expense, name: "日用", icon: "cart.fill", colorHex: 0x4D7148)
                ])
            )
            viewModel.anchorDate = fixedDate(year: 2026, month: 8, day: 10)
            viewModel.timeRange = .year
            viewModel.selectedType = .expense
            viewModel.load()
            let yearCount = viewModel.trend30Cents.count
            let yearTitle = viewModel.timeTitle
            return (yearCount, yearTitle)
        }

        XCTAssertEqual(result.0, 12)
        XCTAssertEqual(result.1, "2026年")
    }

    func testCanGoNextIsFalseForCurrentPeriodAndTrueForPastPeriod() async throws {
        let categoryId = UUID()
        let result = await MainActor.run { () -> (Bool, Bool, Bool) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 4_000, date: fixedDate(year: 2026, month: 5, day: 20), categoryId: categoryId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: categoryId, type: .expense, name: "日用", icon: "cart.fill", colorHex: 0x4D7148)
                ]),
                nowProvider: { self.fixedDate(year: 2026, month: 5, day: 20) }
            )
            viewModel.anchorDate = fixedDate(year: 2026, month: 5, day: 20)
            viewModel.timeRange = .month
            viewModel.load()
            let currentMonthCanGoNext = viewModel.canGoNext

            viewModel.anchorDate = fixedDate(year: 2026, month: 4, day: 10)
            let pastMonthCanGoNext = viewModel.canGoNext

            viewModel.timeRange = .custom
            let customCanGoNext = viewModel.canGoNext
            return (currentMonthCanGoNext, pastMonthCanGoNext, customCanGoNext)
        }

        XCTAssertFalse(result.0)
        XCTAssertTrue(result.1)
        XCTAssertFalse(result.2)
    }

    func testGoPreviousAndGoNextMoveMonthRangeWithoutFutureNavigation() async throws {
        let categoryId = UUID()
        let result = await MainActor.run { () -> (String, [String], Bool, String, [String], Bool) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2026, month: 4, day: 1), categoryId: categoryId),
                    makeBill(type: .expense, cents: 2_000, date: fixedDate(year: 2026, month: 4, day: 30), categoryId: categoryId),
                    makeBill(type: .expense, cents: 3_000, date: fixedDate(year: 2026, month: 5, day: 20), categoryId: categoryId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: categoryId, type: .expense, name: "日用", icon: "cart.fill", colorHex: 0x4D7148)
                ]),
                nowProvider: { self.fixedDate(year: 2026, month: 5, day: 20) }
            )
            viewModel.anchorDate = fixedDate(year: 2026, month: 5, day: 20)
            viewModel.timeRange = .month
            viewModel.selectedType = .expense
            viewModel.load()

            viewModel.goPrevious()
            let previousTitle = viewModel.timeTitle
            let previousKeys = viewModel.dayKeys
            let previousCanGoNext = viewModel.canGoNext

            viewModel.goNext()
            let currentTitle = viewModel.timeTitle
            let currentKeys = viewModel.dayKeys
            let currentCanGoNext = viewModel.canGoNext

            return (previousTitle, previousKeys, previousCanGoNext, currentTitle, currentKeys, currentCanGoNext)
        }

        XCTAssertEqual(result.0, "2026年4月")
        XCTAssertEqual(result.1, ["2026-04-30", "2026-04-01"])
        XCTAssertTrue(result.2)
        XCTAssertEqual(result.3, "2026年5月")
        XCTAssertEqual(result.4, ["2026-05-20"])
        XCTAssertFalse(result.5)
    }

    func testCrossYearWeekUsesOccurredLocalDateBoundaries() async throws {
        let categoryId = UUID()
        let result = await MainActor.run { () -> (String, [String], [Int]) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 900, date: fixedDate(year: 2025, month: 12, day: 28), categoryId: categoryId),
                    makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2025, month: 12, day: 29), categoryId: categoryId),
                    makeBill(type: .expense, cents: 2_000, date: fixedDate(year: 2026, month: 1, day: 4), categoryId: categoryId),
                    makeBill(type: .expense, cents: 3_000, date: fixedDate(year: 2026, month: 1, day: 5), categoryId: categoryId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: categoryId, type: .expense, name: "日用", icon: "cart.fill", colorHex: 0x4D7148)
                ]),
                nowProvider: { self.fixedDate(year: 2026, month: 1, day: 5) }
            )
            viewModel.anchorDate = fixedDate(year: 2026, month: 1, day: 1)
            viewModel.timeRange = .week
            viewModel.selectedType = .expense
            viewModel.load()
            return (viewModel.timeTitle, viewModel.dayKeys, viewModel.trend30Cents)
        }

        XCTAssertEqual(result.0, "12月29日–1月4日")
        XCTAssertEqual(result.1, ["2026-01-04", "2025-12-29"])
        XCTAssertEqual(result.2, [1_000, 0, 0, 0, 0, 0, 2_000])
    }

    func testCustomRangeUsesExplicitStartAndEndDates() async throws {
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
                ]),
                nowProvider: { self.fixedDate(year: 2026, month: 5, day: 20) }
            )
            viewModel.timeRange = .custom
            viewModel.updateCustomRange(
                start: fixedDate(year: 2026, month: 5, day: 1),
                end: fixedDate(year: 2026, month: 5, day: 20)
            )
            viewModel.load()
            return (viewModel.trend30Cents, viewModel.axisLabels, viewModel.dayKeys)
        }

        XCTAssertEqual(result.0.count, 20)
        XCTAssertEqual(result.0.first, 1_000)
        XCTAssertEqual(result.0.last, 2_000)
        XCTAssertEqual(result.1, ["5/1", "5/11", "5/20"])
        XCTAssertEqual(result.2, ["2026-05-20", "2026-05-01"])
    }

    func testCustomRangeSwapsReversedDatesAndClampsFutureEndToToday() async throws {
        let categoryId = UUID()
        let result = await MainActor.run { () -> (String, [String]) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2026, month: 5, day: 18), categoryId: categoryId),
                    makeBill(type: .expense, cents: 2_000, date: fixedDate(year: 2026, month: 5, day: 20), categoryId: categoryId),
                    makeBill(type: .expense, cents: 3_000, date: fixedDate(year: 2026, month: 5, day: 21), categoryId: categoryId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: categoryId, type: .expense, name: "日用", icon: "cart.fill", colorHex: 0x4D7148)
                ]),
                nowProvider: { self.fixedDate(year: 2026, month: 5, day: 20) }
            )
            viewModel.timeRange = .custom
            viewModel.updateCustomRange(
                start: fixedDate(year: 2026, month: 5, day: 22),
                end: fixedDate(year: 2026, month: 5, day: 18)
            )
            viewModel.load()
            return (viewModel.timeTitle, viewModel.dayKeys)
        }

        XCTAssertEqual(result.0, "5月18日–5月20日")
        XCTAssertEqual(result.1, ["2026-05-20", "2026-05-18"])
    }

    func testLongCustomRangeUsesReasonableBucketCount() async throws {
        let categoryId = UUID()
        let result = await MainActor.run { () -> ([Int], [String]) in
            let viewModel = BillsListViewModel(
                repository: MockBillRepository(seed: [
                    makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2026, month: 1, day: 1), categoryId: categoryId),
                    makeBill(type: .expense, cents: 2_000, date: fixedDate(year: 2026, month: 2, day: 15), categoryId: categoryId),
                    makeBill(type: .expense, cents: 3_000, date: fixedDate(year: 2026, month: 5, day: 20), categoryId: categoryId)
                ]),
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: categoryId, type: .expense, name: "日用", icon: "cart.fill", colorHex: 0x4D7148)
                ]),
                nowProvider: { self.fixedDate(year: 2026, month: 5, day: 20) }
            )
            viewModel.timeRange = .custom
            viewModel.updateCustomRange(
                start: fixedDate(year: 2026, month: 1, day: 1),
                end: fixedDate(year: 2026, month: 5, day: 20)
            )
            viewModel.load()
            return (viewModel.trend30Cents, viewModel.axisLabels)
        }

        XCTAssertGreaterThanOrEqual(result.0.count, 10)
        XCTAssertLessThanOrEqual(result.0.count, 31)
        XCTAssertEqual(result.1.count, 3)
    }

    func testBatchFilterUpdateAppliesOnlyOnceAfterLoad() async throws {
        let expenseId = UUID()
        let incomeId = UUID()
        let result = await MainActor.run { () -> Int in
            let repository = CountingBillRepository(seed: [
                makeBill(type: .expense, cents: 1_000, date: fixedDate(year: 2026, month: 5, day: 1), categoryId: expenseId),
                makeBill(type: .income, cents: 5_000, date: fixedDate(year: 2026, month: 5, day: 20), categoryId: incomeId)
            ])
            let viewModel = BillsListViewModel(
                repository: repository,
                categoryRepository: MockCategoryRepository(seed: [
                    makeCategory(id: expenseId, type: .expense, name: "日用", icon: "cart.fill", colorHex: 0x4D7148),
                    makeCategory(id: incomeId, type: .income, name: "奖金", icon: "gift.fill", colorHex: 0xA65566)
                ])
            )
            viewModel.anchorDate = fixedDate(year: 2026, month: 5, day: 20)
            viewModel.load()

            let callsAfterLoad = repository.rangeListCallCount
            viewModel.updateFilters(
                selectedType: .income,
                timeRange: .year,
                anchorDate: fixedDate(year: 2026, month: 8, day: 10)
            )
            return repository.rangeListCallCount - callsAfterLoad
        }

        XCTAssertEqual(result, 2)
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

private final class CountingBillRepository: BillRepository {
    private var storage: [BillRecord]
    private(set) var rangeListCallCount = 0

    init(seed: [BillRecord]) {
        storage = seed
    }

    func create(_ draft: BillDraft) throws -> BillRecord {
        let snapshot = TimePolicy.snapshot(for: draft.occurredAtLocal)
        let record = BillRecord(
            id: UUID(),
            type: draft.type,
            amount: draft.amount,
            occurredAtUTC: snapshot.occurredAtUTC,
            tzId: snapshot.tzId,
            tzOffset: snapshot.tzOffset,
            occurredLocalDate: snapshot.occurredLocalDate,
            note: draft.note,
            categoryId: draft.categoryId,
            isFromRecurring: draft.isFromRecurring,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            trashUntil: nil
        )
        storage.append(record)
        return record
    }

    func update(_ record: BillRecord) throws -> BillRecord {
        guard let index = storage.firstIndex(where: { $0.id == record.id }) else { throw RepositoryError.notFound }
        storage[index] = record
        return record
    }

    func fetch(by dayKey: String) throws -> [BillRecord] {
        storage.filter { $0.occurredLocalDate == dayKey && $0.deletedAt == nil }
    }

    func list() throws -> [BillRecord] {
        storage.filter { $0.deletedAt == nil }
    }

    func list(fromDayKey: String, toDayKey: String, type: BillType?) throws -> [BillRecord] {
        rangeListCallCount += 1
        return storage.filter { record in
            guard record.deletedAt == nil else { return false }
            guard record.occurredLocalDate >= fromDayKey && record.occurredLocalDate <= toDayKey else { return false }
            if let type {
                return record.type == type
            }
            return true
        }
    }

    func list(monthKey: String, type: BillType?) throws -> [BillRecord] {
        storage.filter { record in
            guard record.deletedAt == nil else { return false }
            guard record.occurredLocalDate.hasPrefix(monthKey) else { return false }
            if let type {
                return record.type == type
            }
            return true
        }
    }

    func listYears() throws -> [Int] {
        storage.compactMap { Int($0.occurredLocalDate.prefix(4)) }
    }

    func delete(id: UUID) throws {
        guard let index = storage.firstIndex(where: { $0.id == id }) else { throw RepositoryError.notFound }
        storage.remove(at: index)
    }

    func softDelete(id: UUID, deletedAt: Date, trashUntil: Date) throws {
        guard let record = storage.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        _ = try update(BillRecord(
            id: record.id,
            type: record.type,
            amount: record.amount,
            occurredAtUTC: record.occurredAtUTC,
            tzId: record.tzId,
            tzOffset: record.tzOffset,
            occurredLocalDate: record.occurredLocalDate,
            note: record.note,
            categoryId: record.categoryId,
            isFromRecurring: record.isFromRecurring,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            deletedAt: deletedAt,
            trashUntil: trashUntil
        ))
    }

    func restore(id: UUID) throws {
        guard let record = storage.first(where: { $0.id == id }) else { throw RepositoryError.notFound }
        _ = try update(BillRecord(
            id: record.id,
            type: record.type,
            amount: record.amount,
            occurredAtUTC: record.occurredAtUTC,
            tzId: record.tzId,
            tzOffset: record.tzOffset,
            occurredLocalDate: record.occurredLocalDate,
            note: record.note,
            categoryId: record.categoryId,
            isFromRecurring: record.isFromRecurring,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            deletedAt: nil,
            trashUntil: nil
        ))
    }

    func purgeExpired(asOf date: Date) throws {
        storage.removeAll { ($0.trashUntil ?? Date.distantFuture) < date }
    }
}
