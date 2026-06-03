import Foundation
import Combine

@MainActor
final class QuickEntryViewModel: ObservableObject {
    enum Step {
        case category
        case amount
    }

    enum KeypadKey: Equatable {
        case digit(Int)
        case doubleZero
        case decimal
        case delete
        case calendar
        case minus
        case add
    }

    @Published private(set) var categories: [CategoryRecord] = []
    @Published private(set) var step: Step = .category
    @Published private(set) var availableYears: [Int] = []
    @Published var selectedType: BillType = .expense {
        didSet { loadCategories() }
    }
    @Published var selectedCategory: CategoryRecord?
    @Published var note: String = ""
    @Published var amountText: String = "0"
    @Published var selectedDate: Date {
        didSet {
            guard editingBill != nil else { return }
            if selectedDate != oldValue {
                didUserEditDate = true
            }
        }
    }
    @Published var errorMessage: String?

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private let suggestionService: CategorySuggestionService
    private let editingBill: BillRecord?
    private let nowProvider: () -> Date
    private var categoriesById: [UUID: CategoryRecord] = [:]
    private var orderedSuggestedCategories: [CategoryRecord] = []
    private var didApplyEditing = false
    private var didUserEditDate = false

    init(
        repository: BillRepository,
        categoryRepository: CategoryRepository,
        editingBill: BillRecord? = nil,
        suggestionService: CategorySuggestionService = StubCategorySuggestionService(),
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.billRepository = repository
        self.categoryRepository = categoryRepository
        self.suggestionService = suggestionService
        self.editingBill = editingBill
        self.nowProvider = nowProvider

        if let bill = editingBill {
            self.selectedDate = TimePolicy.editorDate(
                from: bill.occurredAtUTC,
                tzId: bill.tzId,
                tzOffset: bill.tzOffset
            )
            self.selectedType = bill.type
            self.step = .amount
            self.note = bill.note ?? ""
            self.amountText = Self.rawAmountText(fromCents: bill.amount.cents)
        } else {
            self.selectedDate = nowProvider()
        }
    }

    var displayAmountText: String {
        displayAmount
    }

    var displayAmount: String {
        formatTypedAmount(amountText)
    }

    var canSave: Bool {
        selectedCategory != nil && amountCents > 0
    }

    var amountCents: Int {
        cents(from: amountText) ?? 0
    }

    /// 键盘上方横向快捷行要展示的前 N 个分类。
    /// 排序来源由 `CategorySuggestionService` 提供；这里保留「取前 N + 当前选中项一定可见」。
    var suggestedCategories: [CategoryRecord] {
        let limit = QuickEntryLayout.suggestionRowLimit
        var result = Array(orderedSuggestedCategories.prefix(limit))
        guard let selected = selectedCategory,
              selected.type == selectedType,
              categories.contains(where: { $0.id == selected.id }),
              !result.contains(where: { $0.id == selected.id }) else {
            return result
        }
        if !result.isEmpty {
            result.removeLast()
        }
        result.insert(selected, at: 0)
        return result
    }

    func load() {
        loadCategories()
        loadAvailableYears()
        applyEditingSelectionIfNeeded()
    }

    func selectCategory(_ category: CategoryRecord) {
        selectedCategory = category
        step = .amount
    }

    func resetToCategory() {
        step = .category
        selectedCategory = nil
        amountText = "0"
        note = ""
    }

    func handleKey(_ key: KeypadKey) {
        switch key {
        case .digit(let value):
            appendDigit(String(value))
        case .doubleZero:
            appendDoubleZero()
        case .decimal:
            appendDecimal()
        case .delete:
            deleteLast()
        case .calendar:
            break
        case .minus:
            selectedType = .expense
        case .add:
            selectedType = .income
        }
    }

    func save() -> Bool {
        guard let category = selectedCategory else {
            errorMessage = TallyLocalization.text("select_category", locale: LanguageManager.shared.currentLocale)
            return false
        }
        guard let cents = cents(from: amountText) else {
            errorMessage = TallyLocalization.text("amount_invalid", locale: LanguageManager.shared.currentLocale)
            return false
        }
        guard cents > 0 else {
            errorMessage = TallyLocalization.text("amount_positive_required", locale: LanguageManager.shared.currentLocale)
            return false
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let editingBill = editingBill {
                let snapshot: TimeSnapshot
                if didUserEditDate {
                    snapshot = TimePolicy.snapshot(for: selectedDate)
                } else {
                    snapshot = TimeSnapshot(
                        occurredAtUTC: editingBill.occurredAtUTC,
                        tzId: editingBill.tzId,
                        tzOffset: editingBill.tzOffset,
                        occurredLocalDate: editingBill.occurredLocalDate
                    )
                }
                let updatedBill = BillRecord(
                    id: editingBill.id,
                    type: selectedType,
                    amount: Money(cents: cents),
                    occurredAtUTC: snapshot.occurredAtUTC,
                    tzId: snapshot.tzId,
                    tzOffset: snapshot.tzOffset,
                    occurredLocalDate: snapshot.occurredLocalDate,
                    note: trimmedNote.isEmpty ? nil : String(trimmedNote.prefix(QuickEntryLayout.noteLimit)),
                    categoryId: category.id,
                    isFromRecurring: editingBill.isFromRecurring,
                    createdAt: editingBill.createdAt,
                    updatedAt: nowProvider(),
                    deletedAt: editingBill.deletedAt,
                    trashUntil: editingBill.trashUntil
                )
                _ = try billRepository.update(updatedBill)
            } else {
                let draft = BillDraft(
                    type: selectedType,
                    amount: Money(cents: cents),
                    occurredAtLocal: selectedDate,
                    note: trimmedNote.isEmpty ? nil : String(trimmedNote.prefix(QuickEntryLayout.noteLimit)),
                    categoryId: category.id,
                    isFromRecurring: false
                )
                _ = try billRepository.create(draft)
                LastUsedCategoryStore.record(category.id, for: selectedType)
            }
            WidgetSnapshotService.refresh(using: billRepository)
            NotificationCenter.default.post(name: .billDidChange, object: nil)
            errorMessage = nil
            return true
        } catch {
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text("bill_save_failed", locale: LanguageManager.shared.currentLocale)
            )
            return false
        }
    }

    private func loadCategories() {
        do {
            let items = try categoryRepository.list(type: selectedType)
            categoriesById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            categories = sortCategories(items)
            refreshSuggestedCategoryOrder()
            if selectedCategory?.type != selectedType {
                selectedCategory = defaultCategory()
            }
            errorMessage = nil
        } catch {
            categories = []
            orderedSuggestedCategories = []
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text("category_load_failed", locale: LanguageManager.shared.currentLocale)
            )
        }
    }

    private func refreshSuggestedCategoryOrder() {
        let orderedIDs = suggestionService.orderedCategoryIDs(
            type: selectedType,
            now: nowProvider(),
            candidates: categories
        )
        let categoryByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        orderedSuggestedCategories = orderedIDs.compactMap { categoryByID[$0] }
    }

    /// 新建账单时的默认分类：取当前收 / 支类型上次用过的那个；首次使用或该分类已不存在时返回 nil（不预选）。
    /// 编辑模式不在此处理——选中由 `applyEditingSelectionIfNeeded` 按账单实际分类还原。
    private func defaultCategory() -> CategoryRecord? {
        guard editingBill == nil,
              let id = LastUsedCategoryStore.categoryID(for: selectedType) else {
            return nil
        }
        return categories.first { $0.id == id }
    }

    private func loadAvailableYears() {
        do {
            let selectedYear = Calendar.current.component(.year, from: selectedDate)
            let years = try billRepository.listYears()
            let uniqueYears = Array(Set(years + [selectedYear])).sorted()
            availableYears = uniqueYears.isEmpty ? [selectedYear] : uniqueYears
        } catch {
            let selectedYear = Calendar.current.component(.year, from: selectedDate)
            availableYears = [selectedYear]
        }
    }

    private func applyEditingSelectionIfNeeded() {
        guard let bill = editingBill, !didApplyEditing else { return }
        let categoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
        if let found = categoriesById[categoryId] {
            selectedCategory = found
        } else {
            selectedCategory = CategoryRecord(
                id: categoryId,
                type: bill.type,
                name: TallyLocalization.text(.uncategorized, locale: LanguageManager.shared.currentLocale),
                iconKey: "tag",
                colorHex: Int(CategoryColorPalette.defaultHex(for: categoryId)),
                isSystem: true,
                sortOrder: 0
            )
        }
        didApplyEditing = true
    }

    private func sortCategories(_ items: [CategoryRecord]) -> [CategoryRecord] {
        let uncategorized = SystemCategoryID.uncategorized(for: selectedType)
        let filtered = items.filter { $0.id != uncategorized }
        return filtered.sorted { lhs, rhs in
            if lhs.isSystem != rhs.isSystem {
                return lhs.isSystem
            }
            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
            }
            return lhs.name < rhs.name
        }
    }

    private func appendDigit(_ digit: String) {
        if amountText == "0" {
            amountText = digit
            return
        }
        if amountText.contains(".") {
            guard decimalCount(in: amountText) < 2 else { return }
        }
        amountText.append(digit)
    }

    private func appendDoubleZero() {
        if amountText.contains(".") {
            let remaining = 2 - decimalCount(in: amountText)
            guard remaining > 0 else { return }
            amountText.append(String(repeating: "0", count: min(2, remaining)))
            return
        }
        if amountText == "0" {
            return
        }
        amountText.append("00")
    }

    private func appendDecimal() {
        guard !amountText.contains(".") else { return }
        amountText.append(".")
    }

    private func deleteLast() {
        guard amountText.count > 1 else {
            amountText = "0"
            return
        }
        amountText.removeLast()
        if amountText.isEmpty {
            amountText = "0"
        }
    }

    private func formatTypedAmount(_ raw: String) -> String {
        guard !raw.isEmpty else { return "0" }
        guard raw != "0" else { return "0" }
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        let integerRaw = String(parts.first ?? "0")
        let integerValue = Int(integerRaw) ?? 0
        let integer = Self.amountGroupingFormatter.string(from: NSNumber(value: integerValue)) ?? integerRaw
        guard parts.count > 1 else { return integer }
        return integer + "." + String(parts[1])
    }

    private func decimalCount(in text: String) -> Int {
        guard let dotIndex = text.firstIndex(of: ".") else { return 0 }
        let decimals = text[text.index(after: dotIndex)...]
        return decimals.count
    }

    private static func rawAmountText(fromCents cents: Int) -> String {
        let integerPart = cents / 100
        let fraction = cents % 100
        if fraction == 0 {
            return "\(integerPart)"
        }
        if fraction % 10 == 0 {
            return "\(integerPart).\(fraction / 10)"
        }
        return String(format: "%d.%02d", integerPart, fraction)
    }

    private func cents(from raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.contains(where: { $0.isNumber }) else { return nil }
        guard trimmed.allSatisfy({ $0.isNumber || $0 == "." }) else { return nil }
        let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count > 2 { return nil }
        let integerText = String(parts.first ?? "0")
        guard integerText.isEmpty || integerText.allSatisfy(\.isNumber) else { return nil }
        let integerPart = Int(integerText.isEmpty ? "0" : integerText) ?? 0
        let fraction = parts.count > 1 ? String(parts[1]) : ""
        guard fraction.allSatisfy(\.isNumber) else { return nil }
        guard fraction.count <= 2 else { return nil }
        let padded = String(fraction.prefix(2)).padding(toLength: 2, withPad: "0", startingAt: 0)
        guard let fractionValue = Int(padded) else { return nil }
        return integerPart * 100 + fractionValue
    }

    private static let amountGroupingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
