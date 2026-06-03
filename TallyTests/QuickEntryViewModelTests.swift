import XCTest
@testable import Tally

final class QuickEntryViewModelTests: XCTestCase {
    private let lastUsedSuite = "QuickEntryViewModelTests.lastUsed"
    private var savedDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        savedDefaults = LastUsedCategoryStore.defaults
        let suite = UserDefaults(suiteName: lastUsedSuite)!
        suite.removePersistentDomain(forName: lastUsedSuite)
        LastUsedCategoryStore.defaults = suite
    }

    override func tearDown() {
        LastUsedCategoryStore.defaults.removePersistentDomain(forName: lastUsedSuite)
        LastUsedCategoryStore.defaults = savedDefaults
        super.tearDown()
    }

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

    func testChangingBillTypeSelectsLastUsedCategoryForThatType() async throws {
        let expenseCategory = makeCategory(type: .expense, name: "午餐")
        let incomeCategory = makeCategory(type: .income, name: "薪资")
        LastUsedCategoryStore.record(incomeCategory.id, for: .income)

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

    func testFirstLaunchWithoutHistoryDoesNotPreselectCategory() async throws {
        let category = makeCategory(type: .expense, name: "晚餐")

        let selected = await MainActor.run { () -> CategoryRecord? in
            let viewModel = QuickEntryViewModel(
                repository: InMemoryBillRepository(),
                categoryRepository: MockCategoryRepository(seed: [category])
            )
            viewModel.load()
            return viewModel.selectedCategory
        }

        XCTAssertNil(selected)
    }

    func testSavingRecordsLastUsedCategoryAsNextDefault() async throws {
        let category = makeCategory(type: .expense, name: "咖啡")

        let result = await MainActor.run { () -> (UUID?, UUID?) in
            let repository = InMemoryBillRepository()
            let categoryRepository = MockCategoryRepository(seed: [category])

            let first = QuickEntryViewModel(repository: repository, categoryRepository: categoryRepository)
            first.load()
            first.selectCategory(category)
            first.handleKey(.digit(5))
            _ = first.save()

            let second = QuickEntryViewModel(repository: repository, categoryRepository: categoryRepository)
            second.load()
            return (first.selectedCategory?.id, second.selectedCategory?.id)
        }

        XCTAssertEqual(result.0, category.id)
        XCTAssertEqual(result.1, category.id)
    }

    func testLastUsedCategoryIsTrackedPerBillType() async throws {
        let expense = makeCategory(type: .expense, name: "咖啡")
        let income = makeCategory(type: .income, name: "薪资")

        let result = await MainActor.run { () -> (UUID?, CategoryRecord?) in
            let repository = InMemoryBillRepository()
            let categoryRepository = MockCategoryRepository(seed: [expense, income])

            let first = QuickEntryViewModel(repository: repository, categoryRepository: categoryRepository)
            first.load()
            first.selectCategory(expense)
            first.handleKey(.digit(5))
            _ = first.save()

            let second = QuickEntryViewModel(repository: repository, categoryRepository: categoryRepository)
            second.load()
            let expenseDefault = second.selectedCategory?.id
            second.handleKey(.add)
            return (expenseDefault, second.selectedCategory)
        }

        XCTAssertEqual(result.0, expense.id)
        XCTAssertNil(result.1)
    }

    func testStoredCategoryNoLongerAvailableFallsBackToNoSelection() async throws {
        let available = makeCategory(type: .expense, name: "咖啡")
        let removedID = UUID()

        let selected = await MainActor.run { () -> CategoryRecord? in
            LastUsedCategoryStore.record(removedID, for: .expense)
            let viewModel = QuickEntryViewModel(
                repository: InMemoryBillRepository(),
                categoryRepository: MockCategoryRepository(seed: [available])
            )
            viewModel.load()
            return viewModel.selectedCategory
        }

        XCTAssertNil(selected)
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

    func testSuggestedCategoriesTakesLeadingBySortOrderWithinLimit() async throws {
        let seed = (0..<8).map { makeCategory(type: .expense, name: "c\($0)", sortOrder: $0) }

        let names = await MainActor.run { () -> [String] in
            let viewModel = QuickEntryViewModel(
                repository: InMemoryBillRepository(),
                categoryRepository: MockCategoryRepository(seed: seed)
            )
            viewModel.load()
            return viewModel.suggestedCategories.map(\.name)
        }

        // 取前 suggestionRowLimit 个（=6），按 sortOrder 升序
        XCTAssertEqual(names, ["c0", "c1", "c2", "c3", "c4", "c5"])
    }

    func testSuggestedCategoriesForcesSelectedVisibleWhenBeyondLimit() async throws {
        let seed = (0..<8).map { makeCategory(type: .expense, name: "c\($0)", sortOrder: $0) }
        // 选中排在第 8 位（sortOrder=7）的分类，它本不在前 6
        let tail = seed[7]

        let result = await MainActor.run { () -> ([String], Int) in
            let viewModel = QuickEntryViewModel(
                repository: InMemoryBillRepository(),
                categoryRepository: MockCategoryRepository(seed: seed)
            )
            viewModel.load()
            viewModel.selectCategory(tail)
            let names = viewModel.suggestedCategories.map(\.name)
            return (names, viewModel.suggestedCategories.count)
        }

        XCTAssertEqual(result.0.first, "c7")           // 选中项被挤到第一，保证可见
        XCTAssertEqual(result.1, QuickEntryLayout.suggestionRowLimit) // 长度不超限
        XCTAssertTrue(result.0.contains("c7"))
    }

    func testSuggestedCategoriesKeepsSelectedInPlaceWhenAlreadyVisible() async throws {
        let seed = (0..<6).map { makeCategory(type: .expense, name: "c\($0)", sortOrder: $0) }
        let third = seed[2]

        let names = await MainActor.run { () -> [String] in
            let viewModel = QuickEntryViewModel(
                repository: InMemoryBillRepository(),
                categoryRepository: MockCategoryRepository(seed: seed)
            )
            viewModel.load()
            viewModel.selectCategory(third)
            return viewModel.suggestedCategories.map(\.name)
        }

        // 选中项已在可见范围内时不重排，保持 sortOrder 原位（守肌肉记忆）
        XCTAssertEqual(names, ["c0", "c1", "c2", "c3", "c4", "c5"])
    }

    func testSuggestedCategoriesUsesServiceOrderAndKeepsSelectedVisible() async throws {
        let seed = (0..<8).map { makeCategory(type: .expense, name: "c\($0)", sortOrder: $0) }
        let serviceOrder = seed.reversed().map(\.id)
        let tailInServiceOrder = seed[0]

        let result = await MainActor.run { () -> ([String], [String], Int) in
            let viewModel = QuickEntryViewModel(
                repository: InMemoryBillRepository(),
                categoryRepository: MockCategoryRepository(seed: seed),
                suggestionService: OrderedCategorySuggestionService(orderedIDs: serviceOrder)
            )
            viewModel.load()
            let serviceOrderedNames = viewModel.suggestedCategories.map(\.name)
            viewModel.selectCategory(tailInServiceOrder)
            let selectedVisibleNames = viewModel.suggestedCategories.map(\.name)
            return (serviceOrderedNames, selectedVisibleNames, selectedVisibleNames.count)
        }

        XCTAssertEqual(result.0, ["c7", "c6", "c5", "c4", "c3", "c2"])
        XCTAssertEqual(result.1, ["c0", "c7", "c6", "c5", "c4", "c3"])
        XCTAssertEqual(result.2, QuickEntryLayout.suggestionRowLimit)
    }

    @MainActor
    private func makeViewModel() -> QuickEntryViewModel {
        QuickEntryViewModel(
            repository: InMemoryBillRepository(),
            categoryRepository: MockCategoryRepository(seed: [makeCategory(type: .expense, name: "午餐")])
        )
    }

    private func makeCategory(type: BillType, name: String, sortOrder: Int = 0) -> CategoryRecord {
        CategoryRecord(
            id: UUID(),
            type: type,
            name: name,
            iconKey: type == .expense ? "fork.knife" : "banknote.fill",
            colorHex: nil,
            isSystem: false,
            sortOrder: sortOrder
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

private struct OrderedCategorySuggestionService: CategorySuggestionService {
    let orderedIDs: [UUID]

    func orderedCategoryIDs(type: BillType, now: Date, candidates: [CategoryRecord]) -> [UUID] {
        orderedIDs
    }
}
