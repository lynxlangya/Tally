import CoreData
import XCTest
@testable import Tally

final class CategorySeedColorTests: XCTestCase {
    @MainActor
    func testSeedUsesBrandSwatchColorsForMappedDefaultCategories() throws {
        let context = try makeContext()
        try CoreDataSeedService(context: context).seedIfNeeded()

        let categories = try fetchCategories(in: context)
        XCTAssertEqual(colorHex(for: "午餐", in: categories), CoreDataSeedService.brandColorHexByCategoryName["午餐"])
        XCTAssertEqual(colorHex(for: "咖啡", in: categories), CoreDataSeedService.brandColorHexByCategoryName["咖啡"])
        XCTAssertEqual(colorHex(for: "晚餐", in: categories), CoreDataSeedService.brandColorHexByCategoryName["晚餐"])
        XCTAssertEqual(colorHex(for: "房租", in: categories), CoreDataSeedService.brandColorHexByCategoryName["房租"])

        let uncategorized = categories.filter { $0.value(forKey: "name") as? String == "未分类" }
        XCTAssertEqual(uncategorized.count, 2)
        XCTAssertTrue(
            uncategorized.allSatisfy {
                ($0.value(forKey: "colorHex") as? Int64) == Int64(CoreDataSeedService.brandColorHexByCategoryName["未分类"] ?? 0)
            }
        )
    }

    @MainActor
    func testMigrationUpdatesPresetCategoriesSkipsUserCategoriesAndRunsOnce() throws {
        let context = try makeContext()
        let defaults = try makeDefaults()

        let presetLunchID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        let presetBreakfastID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        let userLunchID = UUID()

        try insertCategory(id: presetLunchID, name: "午餐", colorHex: 0x010203, isSystem: false, in: context)
        try insertCategory(id: presetBreakfastID, name: "早餐", colorHex: 0x040506, isSystem: false, in: context)
        try insertCategory(id: userLunchID, name: "午餐", colorHex: 0x070809, isSystem: false, in: context)

        try CoreDataSeedService.migrateLegacyCategoryColors(in: context, userDefaults: defaults)

        XCTAssertEqual(try colorHex(id: presetLunchID, in: context), CoreDataSeedService.brandColorHexByCategoryName["午餐"])
        XCTAssertNotEqual(try colorHex(id: presetBreakfastID, in: context), 0x040506)
        XCTAssertEqual(try colorHex(id: userLunchID, in: context), 0x070809)
        XCTAssertTrue(defaults.bool(forKey: CoreDataSeedService.colorMigrationFlagKey))

        try setColorHex(id: presetLunchID, colorHex: 0x111213, in: context)
        try CoreDataSeedService.migrateLegacyCategoryColors(in: context, userDefaults: defaults)
        XCTAssertEqual(try colorHex(id: presetLunchID, in: context), 0x111213)
    }
}

private extension CategorySeedColorTests {
    func makeContext() throws -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "Tally")
        guard let description = container.persistentStoreDescriptions.first else {
            throw TestError.missingPersistentStoreDescription
        }
        description.url = URL(fileURLWithPath: "/dev/null")

        var loadError: Error?
        let expectation = expectation(description: "Load in-memory CoreData store")
        container.loadPersistentStores { _, error in
            loadError = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        if let loadError { throw loadError }
        return container.viewContext
    }

    func makeDefaults() throws -> UserDefaults {
        let suiteName = "CategorySeedColorTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError.missingUserDefaultsSuite
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func insertCategory(
        id: UUID,
        name: String,
        colorHex: Int,
        isSystem: Bool,
        in context: NSManagedObjectContext
    ) throws {
        let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
        object.setValue(id, forKey: "id")
        object.setValue(BillType.expense.rawValue, forKey: "type")
        object.setValue(name, forKey: "name")
        object.setValue("fork.knife", forKey: "iconKey")
        object.setValue(Int64(colorHex), forKey: "colorHex")
        object.setValue(isSystem, forKey: "isSystem")
        object.setValue(Int64(99), forKey: "sortOrder")
        try context.save()
    }

    func fetchCategories(in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        return try context.fetch(request)
    }

    func colorHex(for name: String, in categories: [NSManagedObject]) -> Int? {
        categories
            .first { $0.value(forKey: "name") as? String == name }
            .flatMap { ($0.value(forKey: "colorHex") as? Int64).flatMap { Int(exactly: $0) } }
    }

    func colorHex(id: UUID, in context: NSManagedObjectContext) throws -> Int? {
        try fetchCategory(id: id, in: context)
            .flatMap { ($0.value(forKey: "colorHex") as? Int64).flatMap { Int(exactly: $0) } }
    }

    func setColorHex(id: UUID, colorHex: Int, in context: NSManagedObjectContext) throws {
        let category = try XCTUnwrap(fetchCategory(id: id, in: context))
        category.setValue(Int64(colorHex), forKey: "colorHex")
        try context.save()
    }

    func fetchCategory(id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }
}

private enum TestError: Error {
    case missingPersistentStoreDescription
    case missingUserDefaultsSuite
}
