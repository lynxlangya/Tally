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
            categories = try repository.list(type: type)
            userCategoryCount = categories.filter { !$0.isSystem }.count
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func addCategory(name: String, iconKey: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "分类名称不能为空"
            return
        }
        guard !isAtLimit else {
            errorMessage = "最多新增 30 个分类"
            return
        }

        let sortOrder = (categories.map { $0.sortOrder }.max() ?? 0) + 1
        let record = CategoryRecord(
            id: UUID(),
            type: selectedType,
            name: trimmed,
            iconKey: iconKey,
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
}
