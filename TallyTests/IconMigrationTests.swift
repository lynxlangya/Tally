import CoreData
import UIKit
import XCTest
@testable import Tally

final class IconMigrationTests: XCTestCase {
    @MainActor
    func testLegacyIconMigrationRemapsKnownKeysAndPreservesUnknownKeys() throws {
        let context = try makeContext()
        let defaults = try makeDefaults()
        let knownID = UUID()
        let unknownID = UUID()

        try insertCategory(id: knownID, iconKey: "questionmark", in: context)
        try insertCategory(id: unknownID, iconKey: "custom.legacy.icon", in: context)

        try CoreDataSeedService.migrateLegacyIconKeys(in: context, userDefaults: defaults)

        XCTAssertEqual(try iconKey(id: knownID, in: context), "tag")
        XCTAssertEqual(try iconKey(id: unknownID, in: context), "custom.legacy.icon")
        XCTAssertTrue(defaults.bool(forKey: CoreDataSeedService.iconMigrationFlagKey))
    }

    @MainActor
    func testLegacyIconMigrationRunsOnce() throws {
        let context = try makeContext()
        let defaults = try makeDefaults()
        let categoryID = UUID()

        try insertCategory(id: categoryID, iconKey: "cart.fill", in: context)
        try CoreDataSeedService.migrateLegacyIconKeys(in: context, userDefaults: defaults)
        XCTAssertEqual(try iconKey(id: categoryID, in: context), "shopping-cart")

        try setIconKey(id: categoryID, iconKey: "fork.knife", in: context)
        try CoreDataSeedService.migrateLegacyIconKeys(in: context, userDefaults: defaults)

        XCTAssertEqual(try iconKey(id: categoryID, in: context), "fork.knife")
    }

    @MainActor
    func testPresetIconMigrationUpdatesOnlyKnownStalePresetIcons() throws {
        let context = try makeContext()
        let defaults = try makeDefaults()
        let breakfastID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        let coffeeID = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
        let customID = UUID()

        try insertCategory(id: breakfastID, name: "早餐", iconKey: "coffee", in: context)
        try insertCategory(id: coffeeID, name: "咖啡", iconKey: "coffee", in: context)
        try insertCategory(id: customID, name: "我的早餐", iconKey: "coffee", in: context)

        try CoreDataSeedService.migratePresetIconKeys(in: context, userDefaults: defaults)

        XCTAssertEqual(try iconKey(id: breakfastID, in: context), "cooking-pot")
        XCTAssertEqual(try iconKey(id: coffeeID, in: context), "coffee")
        XCTAssertEqual(try iconKey(id: customID, in: context), "coffee")
        XCTAssertTrue(defaults.bool(forKey: CoreDataSeedService.presetIconMigrationFlagKey))
    }

    @MainActor
    func testDefaultPresetIconsAreUniqueWithinEachBillType() throws {
        let context = try makeContext()

        try CoreDataSeedService(context: context).seedIfNeeded()

        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        let categories = try context.fetch(request)
        for type in [BillType.expense, .income] {
            let icons = categories.compactMap { category -> String? in
                guard
                    category.value(forKey: "type") as? String == type.rawValue
                else {
                    return nil
                }
                return category.value(forKey: "iconKey") as? String
            }

            XCTAssertEqual(icons.count, Set(icons).count, "\(type.rawValue) preset icons should be unique")
        }
    }

    func testCategoryAndUtilityIconCatalogsMatchPhosphorAssetSet() {
        XCTAssertEqual(TallyIcon.Catalog.all.count, 88)
        XCTAssertEqual(Set(TallyIcon.Catalog.all).count, 88)
        XCTAssertEqual(CategoryIconCatalog.sheetIcons.count, 88)

        XCTAssertEqual(TallyIcon.Catalog.utility.count, 8)
        XCTAssertEqual(Set(TallyIcon.Catalog.utility).count, 8)

        for icon in TallyIcon.Catalog.all + TallyIcon.Catalog.utility {
            XCTAssertNotNil(UIImage(named: icon), icon)
        }
    }

    func testCategoryIconAccessibilityLabelsCoverSheetIcons() {
        for icon in CategoryIconCatalog.sheetIcons {
            let label = CategoryIconCatalog.accessibilityLabel(for: icon)
            XCTAssertFalse(label.isEmpty, icon)
            XCTAssertNotEqual(label, icon, icon)
        }
    }
}

private extension IconMigrationTests {
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
        let suiteName = "IconMigrationTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestError.missingUserDefaultsSuite
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func insertCategory(
        id: UUID,
        name: String = "测试",
        iconKey: String,
        in context: NSManagedObjectContext
    ) throws {
        let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
        object.setValue(id, forKey: "id")
        object.setValue(BillType.expense.rawValue, forKey: "type")
        object.setValue(name, forKey: "name")
        object.setValue(iconKey, forKey: "iconKey")
        object.setValue(Int64(0xB8553E), forKey: "colorHex")
        object.setValue(false, forKey: "isSystem")
        object.setValue(Int64(1), forKey: "sortOrder")
        try context.save()
    }

    func iconKey(id: UUID, in context: NSManagedObjectContext) throws -> String? {
        try fetchCategory(id: id, in: context)?.value(forKey: "iconKey") as? String
    }

    func setIconKey(id: UUID, iconKey: String, in context: NSManagedObjectContext) throws {
        let category = try XCTUnwrap(fetchCategory(id: id, in: context))
        category.setValue(iconKey, forKey: "iconKey")
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
