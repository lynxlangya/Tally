import Foundation
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published private(set) var categories: [CategoryRecord] = []
    @Published private(set) var userCategoryCount: Int = 0
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedType: BillType = .expense

    private let repository: CategoryRepository
    private let maxUserCategories = 30

    init(repository: CategoryRepository) {
        self.repository = repository
    }

    var isAtLimit: Bool {
        userCategoryCount >= maxUserCategories
    }

    func load(type: BillType) {
        selectedType = type
        do {
            let fetched = try repository.list(type: type)
            categories = fetched
            userCategoryCount = fetched.filter { !$0.isSystem }.count
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func addCategory(name: String, iconKey: String, colorHex: UInt32) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "分类名称不能为空"
            return
        }
        guard !isAtLimit else {
            errorMessage = "最多新增 30 个分类"
            return
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
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func updateCategory(id: UUID, name: String, iconKey: String, colorHex: UInt32) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "分类名称不能为空"
            return
        }

        guard let existing = categories.first(where: { $0.id == id }) else {
            errorMessage = "未找到分类"
            return
        }
        guard !existing.isSystem else {
            errorMessage = "系统分类不可编辑"
            return
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
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func deleteCategory(_ category: CategoryRecord) {
        guard !category.isSystem else {
            errorMessage = "系统分类不可删除"
            return
        }
        do {
            let destination = SystemCategoryID.uncategorized(for: category.type)
            try repository.delete(id: category.id, migrateTo: destination)
            load(type: selectedType)
            persistOrder()
        } catch {
            errorMessage = String(describing: error)
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

    func persistOrder() {
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
        } catch {
            errorMessage = String(describing: error)
            load(type: selectedType)
        }
    }
}
