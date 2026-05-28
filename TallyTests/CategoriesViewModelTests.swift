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

    func testLoadFailureUsesFriendlyMessage() {
        let viewModel = CategoriesViewModel(
            repository: FailingCategoryRepository(error: RepositoryError.invalidData(field: "Category.name"))
        )

        viewModel.load(type: .expense)

        XCTAssertEqual(viewModel.errorMessage, "本地数据异常，请稍后重试")
        XCTAssertFalse(viewModel.errorMessage?.contains("Category.name") ?? true)
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

    func testAddCategoryPersistsRecordAndReloadsList() {
        let system = makeCategory(
            id: SystemCategoryID.uncategorizedExpense,
            name: "未分类",
            isSystem: true,
            sortOrder: 0
        )
        let repository = RecordingCategoryRepository(seed: [system])
        let viewModel = CategoriesViewModel(repository: repository)
        viewModel.load(type: .expense)

        let error = viewModel.addCategory(name: " 午餐 ", iconKey: "cup.and.saucer.fill", colorHex: 0xD6864A)

        XCTAssertNil(error)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(repository.createdRecords.first?.name, "午餐")
        XCTAssertEqual(repository.createdRecords.first?.iconKey, "cup.and.saucer.fill")
        XCTAssertEqual(repository.createdRecords.first?.colorHex, 0xD6864A)
        XCTAssertEqual(repository.createdRecords.first?.sortOrder, 1)
        XCTAssertEqual(viewModel.categories.map(\.name), ["未分类", "午餐"])
    }

    func testAddCategoryRejectsDuplicateNameBeforePersisting() {
        let first = makeCategory(name: "午餐", isSystem: false, sortOrder: 1)
        let repository = RecordingCategoryRepository(seed: [first])
        let viewModel = CategoriesViewModel(repository: repository)
        viewModel.load(type: .expense)

        let error = viewModel.addCategory(name: "午餐", iconKey: "cart.fill", colorHex: 0xB8553E)

        XCTAssertEqual(error, "分类名称已存在")
        XCTAssertEqual(viewModel.errorMessage, "分类名称已存在")
        XCTAssertTrue(repository.createdRecords.isEmpty)
    }

    func testUpdateCategoryPersistsEditedFields() {
        let category = makeCategory(name: "午餐", isSystem: false, sortOrder: 1)
        let repository = RecordingCategoryRepository(seed: [category])
        let viewModel = CategoriesViewModel(repository: repository)
        viewModel.load(type: .expense)

        let error = viewModel.updateCategory(
            id: category.id,
            name: "晚餐",
            iconKey: "birthday.cake.fill",
            colorHex: 0x7A8043
        )

        XCTAssertNil(error)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(repository.updatedRecords.last?.id, category.id)
        XCTAssertEqual(repository.updatedRecords.last?.name, "晚餐")
        XCTAssertEqual(repository.updatedRecords.last?.iconKey, "birthday.cake.fill")
        XCTAssertEqual(repository.updatedRecords.last?.colorHex, 0x7A8043)
        XCTAssertEqual(repository.updatedRecords.last?.sortOrder, category.sortOrder)
    }

    func testUpdateCategoryRejectsDuplicateNameBeforePersisting() {
        let first = makeCategory(name: "午餐", isSystem: false, sortOrder: 1)
        let second = makeCategory(name: "晚餐", isSystem: false, sortOrder: 2)
        let repository = RecordingCategoryRepository(seed: [first, second])
        let viewModel = CategoriesViewModel(repository: repository)
        viewModel.load(type: .expense)

        let error = viewModel.updateCategory(
            id: second.id,
            name: "午餐",
            iconKey: second.iconKey,
            colorHex: UInt32(second.colorHex ?? 0)
        )

        XCTAssertEqual(error, "分类名称已存在")
        XCTAssertEqual(viewModel.errorMessage, "分类名称已存在")
        XCTAssertTrue(repository.updatedRecords.isEmpty)
    }

    func testUpdateCategoryPostsCategoryDidChangeAfterSuccessfulPersist() {
        let category = makeCategory(name: "午餐", isSystem: false, sortOrder: 1)
        let repository = RecordingCategoryRepository(seed: [category])
        let viewModel = CategoriesViewModel(repository: repository)
        viewModel.load(type: .expense)
        var notificationCount = 0
        let observer = NotificationCenter.default.addObserver(
            forName: .categoryDidChange,
            object: nil,
            queue: nil
        ) { _ in
            notificationCount += 1
        }

        _ = viewModel.updateCategory(
            id: category.id,
            name: "晚餐",
            iconKey: "birthday.cake.fill",
            colorHex: 0x7A8043
        )

        NotificationCenter.default.removeObserver(observer)
        XCTAssertEqual(notificationCount, 1)
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

    func testPersistOrderKeepsUserCategoriesAfterSystemCategory() {
        let system = makeCategory(
            id: SystemCategoryID.uncategorizedExpense,
            name: "未分类",
            isSystem: true,
            sortOrder: 0
        )
        let first = makeCategory(name: "餐饮", isSystem: false, sortOrder: 1)
        let second = makeCategory(name: "购物", isSystem: false, sortOrder: 2)
        let repository = RecordingCategoryRepository(seed: [system, first, second])
        let viewModel = CategoriesViewModel(repository: repository)
        viewModel.load(type: .expense)

        viewModel.persistOrder()

        XCTAssertEqual(repository.updatedRecords.map(\.sortOrder), [1, 2])
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

private final class FailingCategoryRepository: CategoryRepository {
    let error: Error

    init(error: Error) {
        self.error = error
    }

    func list(type: BillType) throws -> [CategoryRecord] {
        throw error
    }

    func create(_ record: CategoryRecord) throws {
        throw error
    }

    func update(_ record: CategoryRecord) throws {
        throw error
    }

    func delete(id: UUID, migrateTo destinationId: UUID) throws {
        throw error
    }

    func count(type: BillType) throws -> Int {
        throw error
    }
}

private final class RecordingCategoryRepository: CategoryRepository {
    private var storage: [UUID: CategoryRecord]
    private(set) var createdRecords: [CategoryRecord] = []
    private(set) var updatedId: UUID?
    private(set) var updatedRecords: [CategoryRecord] = []
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
        createdRecords.append(record)
        storage[record.id] = record
    }

    func update(_ record: CategoryRecord) throws {
        updatedId = record.id
        updatedRecords.append(record)
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
