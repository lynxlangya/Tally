import Foundation
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published private(set) var categories: [CategoryRecord] = []
    @Published private(set) var userCategoryCount: Int = 0
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedType: BillType = .expense

    private let repository: CategoryRepository
    let maxUserCategories = 30

    init(repository: CategoryRepository) {
        self.repository = repository
    }

    var isAtLimit: Bool {
        userCategoryCount >= maxUserCategories
    }

    var maxUserCategoriesMessage: String {
        TallyLocalization.format("category_limit_message", locale: LanguageManager.shared.currentLocale, maxUserCategories)
    }

    func load(type: BillType) {
        selectedType = type
        do {
            let fetched = try repository.list(type: type)
            categories = fetched
            userCategoryCount = fetched.filter { !$0.isSystem }.count
            errorMessage = nil
        } catch {
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text("category_load_failed", locale: LanguageManager.shared.currentLocale)
            )
        }
    }

    @discardableResult
    func addCategory(name: String, iconKey: String, colorHex: UInt32) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = TallyLocalization.text("category_name_empty", locale: LanguageManager.shared.currentLocale)
            return errorMessage
        }
        guard !isAtLimit else {
            errorMessage = maxUserCategoriesMessage
            return errorMessage
        }
        guard !categories.contains(where: { !$0.isSystem && $0.name == trimmed }) else {
            errorMessage = TallyLocalization.text("category_name_exists", locale: LanguageManager.shared.currentLocale)
            return errorMessage
        }

        let sortOrder = (categories.filter { !$0.isSystem }.map { $0.sortOrder }.max() ?? 0) + 1
        let record = CategoryRecord(
            id: UUID(),
            type: selectedType,
            name: trimmed,
            iconKey: iconKey,
            colorHex: Int(colorHex),
            isSystem: false,
            sortOrder: sortOrder
        )
        do {
            try repository.create(record)
            load(type: selectedType)
            NotificationCenter.default.post(name: .categoryDidChange, object: nil)
            return nil
        } catch {
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text("category_create_failed", locale: LanguageManager.shared.currentLocale)
            )
            return errorMessage
        }
    }

    @discardableResult
    func updateCategory(id: UUID, name: String, iconKey: String, colorHex: UInt32) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = TallyLocalization.text("category_name_empty", locale: LanguageManager.shared.currentLocale)
            return errorMessage
        }

        guard let existing = categories.first(where: { $0.id == id }) else {
            errorMessage = TallyLocalization.text("category_not_found", locale: LanguageManager.shared.currentLocale)
            return errorMessage
        }
        guard !existing.isSystem else {
            errorMessage = TallyLocalization.text("system_category_edit_forbidden", locale: LanguageManager.shared.currentLocale)
            return errorMessage
        }
        guard !categories.contains(where: { !$0.isSystem && $0.id != id && $0.name == trimmed }) else {
            errorMessage = TallyLocalization.text("category_name_exists", locale: LanguageManager.shared.currentLocale)
            return errorMessage
        }

        let updated = CategoryRecord(
            id: existing.id,
            type: existing.type,
            name: trimmed,
            iconKey: iconKey,
            colorHex: Int(colorHex),
            isSystem: existing.isSystem,
            sortOrder: existing.sortOrder
        )

        do {
            try repository.update(updated)
            load(type: selectedType)
            NotificationCenter.default.post(name: .categoryDidChange, object: nil)
            return nil
        } catch {
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text("category_update_failed", locale: LanguageManager.shared.currentLocale)
            )
            return errorMessage
        }
    }

    func deleteCategory(_ category: CategoryRecord) {
        guard !category.isSystem else {
            errorMessage = TallyLocalization.text("system_category_delete_forbidden", locale: LanguageManager.shared.currentLocale)
            return
        }
        do {
            let destination = SystemCategoryID.uncategorized(for: category.type)
            try repository.delete(id: category.id, migrateTo: destination)
            load(type: selectedType)
            persistOrder(notifiesChange: false)
            NotificationCenter.default.post(name: .categoryDidChange, object: nil)
        } catch {
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text("category_delete_failed", locale: LanguageManager.shared.currentLocale)
            )
        }
    }

    func moveCategory(from source: CategoryRecord, to destination: CategoryRecord) {
        guard !source.isSystem, !destination.isSystem else { return }
        guard let fromIndex = categories.firstIndex(where: { $0.id == source.id }),
              let toIndex = categories.firstIndex(where: { $0.id == destination.id }),
              fromIndex != toIndex else {
            return
        }

        var updated = categories
        let moving = updated.remove(at: fromIndex)
        let insertIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
        updated.insert(moving, at: insertIndex)
        categories = updated
    }

    func persistOrder(notifiesChange: Bool = true) {
        guard !categories.isEmpty else { return }
        let visibleUserCategories = categories.filter { !$0.isSystem }
        let reorderedUserCategories = visibleUserCategories.enumerated().map { index, record in
            CategoryRecord(
                id: record.id,
                type: record.type,
                name: record.name,
                iconKey: record.iconKey,
                colorHex: record.colorHex,
                isSystem: record.isSystem,
                sortOrder: index + 1
            )
        }

        do {
            try reorderedUserCategories.forEach { try repository.update($0) }
            load(type: selectedType)
            errorMessage = nil
            if notifiesChange {
                NotificationCenter.default.post(name: .categoryDidChange, object: nil)
            }
        } catch {
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text("category_order_save_failed", locale: LanguageManager.shared.currentLocale)
            )
            load(type: selectedType)
        }
    }
}
