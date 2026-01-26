import Foundation
import Combine

@MainActor
final class QuickEntryViewModel: ObservableObject {
    enum Step {
        case category
        case amount
    }

    enum KeypadKey {
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
    @Published var selectedDate: Date
    @Published var errorMessage: String?

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private let editingBill: BillRecord?
    private let nowProvider: () -> Date
    private var categoriesById: [UUID: CategoryRecord] = [:]
    private var didApplyEditing = false

    init(
        repository: BillRepository,
        categoryRepository: CategoryRepository,
        editingBill: BillRecord? = nil,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.billRepository = repository
        self.categoryRepository = categoryRepository
        self.editingBill = editingBill
        self.nowProvider = nowProvider

        if let bill = editingBill {
            self.selectedDate = bill.occurredAtUTC
            self.selectedType = bill.type
            self.step = .amount
            self.note = bill.note ?? ""
            self.amountText = Self.rawAmountText(fromCents: bill.amount.cents)
        } else {
            self.selectedDate = nowProvider()
        }
    }

    var displayAmountText: String {
        formatAmount(amountText)
    }

    var amountCents: Int {
        evaluateExpression(amountText) ?? 0
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
            appendOperator("-")
        case .add:
            appendOperator("+")
        }
    }

    func save() -> Bool {
        guard let category = selectedCategory else {
            errorMessage = "请选择分类"
            return false
        }
        guard let cents = evaluateExpression(amountText) else {
            errorMessage = "金额输入有误"
            return false
        }
        guard cents > 0 else {
            errorMessage = "请输入金额"
            return false
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            if let editingBill = editingBill {
                let snapshot = TimePolicy.snapshot(for: selectedDate)
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
            }
            WidgetSnapshotService.refresh(using: billRepository)
            NotificationCenter.default.post(name: .billDidChange, object: nil)
            errorMessage = nil
            return true
        } catch {
            errorMessage = String(describing: error)
            return false
        }
    }

    private func loadCategories() {
        do {
            let items = try categoryRepository.list(type: selectedType)
            categoriesById = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            categories = sortCategories(items)
            errorMessage = nil
        } catch {
            categories = []
            errorMessage = String(describing: error)
        }
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
                name: "未分类",
                iconKey: "questionmark",
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
        let range = currentOperandRange()
        let current = String(amountText[range])
        if current == "0" && !current.contains(".") {
            amountText.replaceSubrange(range, with: digit)
            return
        }
        if current.contains(".") {
            guard decimalCount(in: current) < 2 else { return }
        }
        amountText.append(digit)
    }

    private func appendOperator(_ op: Character) {
        guard !amountText.isEmpty else { return }
        guard let last = amountText.last else { return }
        if last == "+" || last == "-" || last == "." {
            return
        }
        amountText.append(op)
    }

    private func appendDoubleZero() {
        let range = currentOperandRange()
        let current = String(amountText[range])
        if current.contains(".") {
            let remaining = 2 - decimalCount(in: current)
            guard remaining > 0 else { return }
            amountText.append(String(repeating: "0", count: min(2, remaining)))
            return
        }
        if current.isEmpty {
            amountText.append("0")
            return
        }
        if current == "0" {
            return
        }
        amountText.append("00")
    }

    private func appendDecimal() {
        let range = currentOperandRange()
        let current = String(amountText[range])
        guard !current.contains(".") else { return }
        if current.isEmpty {
            amountText.append("0.")
        } else {
            amountText.append(".")
        }
    }

    private func deleteLast() {
        guard !amountText.isEmpty else { return }
        amountText.removeLast()
        if amountText.isEmpty {
            amountText = "0"
        }
    }

    private func formatAmount(_ raw: String) -> String {
        guard !raw.isEmpty else { return "0.00" }
        guard raw != "0" else { return "0.00" }
        return raw
    }

    private func currentOperandRange() -> Range<String.Index> {
        if let index = amountText.lastIndex(where: { $0 == "+" || $0 == "-" }) {
            return amountText.index(after: index)..<amountText.endIndex
        }
        return amountText.startIndex..<amountText.endIndex
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

    private func evaluateExpression(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var total = 0
        var current = ""
        var sign = 1

        for ch in trimmed {
            if ch == "+" || ch == "-" {
                guard !current.isEmpty, let value = cents(from: current) else { return nil }
                total += sign * value
                sign = ch == "+" ? 1 : -1
                current = ""
                continue
            }
            guard ch.isNumber || ch == "." else { return nil }
            if ch == "." && current.contains(".") {
                return nil
            }
            current.append(ch)
        }

        guard !current.isEmpty, let value = cents(from: current) else { return nil }
        total += sign * value
        guard total >= 0 else { return nil }
        return total
    }

    private func cents(from raw: String) -> Int? {
        guard !raw.isEmpty else { return nil }
        guard raw.contains(where: { $0.isNumber }) else { return nil }
        let parts = raw.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count > 2 { return nil }
        let integerPart = Int(parts.first.map(String.init) ?? "") ?? 0
        let fraction = parts.count > 1 ? String(parts[1]) : ""
        guard fraction.count <= 2 else { return nil }
        let padded = String(fraction.prefix(2)).padding(toLength: 2, withPad: "0", startingAt: 0)
        guard let fractionValue = Int(padded) else { return nil }
        return integerPart * 100 + fractionValue
    }
}
