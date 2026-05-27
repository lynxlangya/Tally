import XCTest
@testable import Tally

@MainActor
final class CategoriesViewModelTests: XCTestCase {
    func testLoadKeepsSystemAndUserCategoriesVisible() {
        let system = makeCategory(
            id: SystemCategoryID.uncategorizedExpense,
            name: "未分类",
            isSystem: true,
            sortOrder: 0
        )
        let user = makeCategory(name: "餐饮", isSystem: false, sortOrder: 1)
        let viewModel = CategoriesViewModel(repository: MockCategoryRepository(seed: [system, user]))

        viewModel.load(type: .expense)

        XCTAssertEqual(viewModel.categories.map(\.id), [system.id, user.id])
        XCTAssertEqual(viewModel.userCategoryCount, 1)
    }

    func testDeleteUserCategoryUsesUncategorizedMigrationDestination() {
        let category = makeCategory(name: "餐饮", isSystem: false, sortOrder: 1)
        let repository = RecordingCategoryRepository(seed: [category])
        let viewModel = CategoriesViewModel(repository: repository)
        viewModel.load(type: .expense)

        viewModel.deleteCategory(category)

        XCTAssertEqual(repository.deletedId, category.id)
        XCTAssertEqual(repository.migrateToId, SystemCategoryID.uncategorizedExpense)
    }

    func testSystemCategoryCannotBeDeletedOrUpdated() {
        let system = makeCategory(
            id: SystemCategoryID.uncategorizedExpense,
            name: "未分类",
            isSystem: true,
            sortOrder: 0
        )
        let repository = RecordingCategoryRepository(seed: [system])
        let viewModel = CategoriesViewModel(repository: repository)
        viewModel.load(type: .expense)

        viewModel.updateCategory(id: system.id, name: "其他", iconKey: "tag.fill", colorHex: 0xB8553E)
        viewModel.deleteCategory(system)

        XCTAssertNil(repository.updatedId)
        XCTAssertNil(repository.deletedId)
        XCTAssertEqual(viewModel.errorMessage, "系统分类不可删除")
    }

    private func makeCategory(
        id: UUID = UUID(),
        name: String,
        isSystem: Bool,
        sortOrder: Int
    ) -> CategoryRecord {
        CategoryRecord(
            id: id,
            type: .expense,
            name: name,
            iconKey: "fork.knife",
            colorHex: 0xB8553E,
            isSystem: isSystem,
            sortOrder: sortOrder
        )
    }
}

private final class RecordingCategoryRepository: CategoryRepository {
    private var storage: [UUID: CategoryRecord]
    private(set) var updatedId: UUID?
    private(set) var deletedId: UUID?
    private(set) var migrateToId: UUID?

    init(seed: [CategoryRecord]) {
        storage = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
    }

    func list(type: BillType) throws -> [CategoryRecord] {
        storage.values
            .filter { $0.type == type }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func create(_ record: CategoryRecord) throws {
        storage[record.id] = record
    }

    func update(_ record: CategoryRecord) throws {
        updatedId = record.id
        storage[record.id] = record
    }

    func delete(id: UUID, migrateTo destinationId: UUID) throws {
        deletedId = id
        migrateToId = destinationId
        storage.removeValue(forKey: id)
    }

    func count(type: BillType) throws -> Int {
        storage.values.filter { $0.type == type && !$0.isSystem }.count
    }
}
