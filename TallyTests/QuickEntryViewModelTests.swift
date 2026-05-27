import XCTest
@testable import Tally

final class QuickEntryViewModelTests: XCTestCase {
    func testAmountInputFollowsTypedStringRules() async throws {
        let result = await MainActor.run { () -> (String, Int, String, Int) in
            let viewModel = makeViewModel()

            viewModel.handleKey(.digit(1))
            viewModel.handleKey(.digit(2))
            viewModel.handleKey(.decimal)
            viewModel.handleKey(.digit(3))
            viewModel.handleKey(.doubleZero)
            viewModel.handleKey(.digit(4))
            let firstDisplay = viewModel.displayAmount
            let firstCents = viewModel.amountCents

            viewModel.handleKey(.delete)
            viewModel.handleKey(.delete)
            viewModel.handleKey(.delete)
            viewModel.handleKey(.delete)
            viewModel.handleKey(.delete)

            return (firstDisplay, firstCents, viewModel.amountText, viewModel.amountCents)
        }

        XCTAssertEqual(result.0, "12.30")
        XCTAssertEqual(result.1, 1_230)
        XCTAssertEqual(result.2, "0")
        XCTAssertEqual(result.3, 0)
    }

    func testDoubleZeroNoopsAtZeroAndGroupsIntegerDisplay() async throws {
        let result = await MainActor.run { () -> (String, Int) in
            let viewModel = makeViewModel()
            viewModel.handleKey(.doubleZero)
            viewModel.handleKey(.digit(1))
            viewModel.handleKey(.doubleZero)
            viewModel.handleKey(.doubleZero)
            return (viewModel.displayAmount, viewModel.amountCents)
        }

        XCTAssertEqual(result.0, "10,000")
        XCTAssertEqual(result.1, 1_000_000)
    }

    func testPlusAndMinusToggleBillTypeWithoutArithmetic() async throws {
        let result = await MainActor.run { () -> (String, Int, BillType, BillType) in
            let viewModel = makeViewModel()
            viewModel.handleKey(.digit(1))
            viewModel.handleKey(.add)
            let incomeType = viewModel.selectedType
            viewModel.handleKey(.digit(2))
            viewModel.handleKey(.minus)
            return (viewModel.amountText, viewModel.amountCents, incomeType, viewModel.selectedType)
        }

        XCTAssertEqual(result.0, "12")
        XCTAssertEqual(result.1, 1_200)
        XCTAssertEqual(result.2, .income)
        XCTAssertEqual(result.3, .expense)
    }

    func testCanSaveAndSaveCreatesDraftThroughRepository() async throws {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 20, minute: 30)
        let category = makeCategory(type: .expense, name: "咖啡")

        let result = await MainActor.run { () -> (Bool, Bool, Int, BillType?, Int?, UUID?, String?) in
            let billRepository = InMemoryBillRepository()
            let viewModel = QuickEntryViewModel(
                repository: billRepository,
                categoryRepository: MockCategoryRepository(seed: [category]),
                nowProvider: { now }
            )
            viewModel.load()
            let canSaveBeforeAmount = viewModel.canSave
            viewModel.selectCategory(category)
            viewModel.handleKey(.digit(9))
            viewModel.handleKey(.decimal)
            viewModel.handleKey(.digit(9))
            viewModel.note = "abcdefg"
            let didSave = viewModel.save()
            let draft = billRepository.createdDrafts.first
            return (
                canSaveBeforeAmount,
                didSave,
                billRepository.createdDrafts.count,
                draft?.type,
                draft?.amount.cents,
                draft?.categoryId,
                draft?.note
            )
        }

        XCTAssertFalse(result.0)
        XCTAssertTrue(result.1)
        XCTAssertEqual(result.2, 1)
        XCTAssertEqual(result.3, .expense)
        XCTAssertEqual(result.4, 990)
        XCTAssertEqual(result.5, category.id)
        XCTAssertEqual(result.6, "abcdef")
    }

    func testChangingBillTypeLoadsMatchingCategoriesAndClearsMismatchedSelection() async throws {
        let expenseCategory = makeCategory(type: .expense, name: "午餐")
        let incomeCategory = makeCategory(type: .income, name: "薪资")

        let result = await MainActor.run { () -> (CategoryRecord?, [CategoryRecord], BillType) in
            let viewModel = QuickEntryViewModel(
                repository: InMemoryBillRepository(),
                categoryRepository: MockCategoryRepository(seed: [expenseCategory, incomeCategory])
            )
            viewModel.load()
            viewModel.selectCategory(expenseCategory)
            viewModel.handleKey(.add)
            return (viewModel.selectedCategory, viewModel.categories, viewModel.selectedType)
        }

        XCTAssertEqual(result.0?.id, incomeCategory.id)
        XCTAssertEqual(result.1.map(\.id), [incomeCategory.id])
        XCTAssertEqual(result.2, .income)
    }

    func testChangingBillTypeDoesNotAutoselectWhenNoMatchingCategoryExists() async throws {
        let expenseCategory = makeCategory(type: .expense, name: "午餐")

        let result = await MainActor.run { () -> (CategoryRecord?, [CategoryRecord], Bool) in
            let viewModel = QuickEntryViewModel(
                repository: InMemoryBillRepository(),
                categoryRepository: MockCategoryRepository(seed: [expenseCategory])
            )
            viewModel.load()
            viewModel.selectCategory(expenseCategory)
            viewModel.handleKey(.add)
            return (viewModel.selectedCategory, viewModel.categories, viewModel.canSave)
        }

        XCTAssertNil(result.0)
        XCTAssertTrue(result.1.isEmpty)
        XCTAssertFalse(result.2)
    }

    @MainActor
    private func makeViewModel() -> QuickEntryViewModel {
        QuickEntryViewModel(
            repository: InMemoryBillRepository(),
            categoryRepository: MockCategoryRepository(seed: [makeCategory(type: .expense, name: "午餐")])
        )
    }

    private func makeCategory(type: BillType, name: String) -> CategoryRecord {
        CategoryRecord(
            id: UUID(),
            type: type,
            name: name,
            iconKey: type == .expense ? "fork.knife" : "banknote.fill",
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
