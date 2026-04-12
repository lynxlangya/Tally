import XCTest
@testable import JustOne

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

    private func makeBill(
        id: UUID,
        categoryId: UUID,
        occurredAtUTC: Date,
        occurredLocalDate: String
    ) -> BillRecord {
        BillRecord(
            id: id,
            type: .expense,
            amount: Money(cents: 1234),
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
