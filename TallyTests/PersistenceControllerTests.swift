import CoreData
import XCTest
@testable import Tally

final class PersistenceControllerTests: XCTestCase {
    @MainActor
    func testModelDefinesIndexesAndUniqueConstraintsForHotLookupFields() throws {
        let model = PersistenceController(inMemory: true, runsStartupSeed: false)
            .container
            .managedObjectModel

        let bill = try entity(named: "Bill", in: model)
        XCTAssertTrue(uniquePropertyNameSets(for: bill).contains(["id"]))
        XCTAssertTrue(indexedPropertyNames(for: bill).contains("id"))
        XCTAssertTrue(indexedPropertyNames(for: bill).contains("occurredLocalDate"))

        let category = try entity(named: "Category", in: model)
        XCTAssertTrue(uniquePropertyNameSets(for: category).contains(["id"]))
        XCTAssertTrue(indexedPropertyNames(for: category).contains("id"))

        let recurringTask = try entity(named: "RecurringTask", in: model)
        XCTAssertTrue(uniquePropertyNameSets(for: recurringTask).contains(["id"]))
        XCTAssertTrue(indexedPropertyNames(for: recurringTask).contains("id"))
    }

    @MainActor
    func testCurrentIndexedModelLightweightMigratesLegacyStore() throws {
        let currentModel = PersistenceController(inMemory: true, runsStartupSeed: false)
            .container
            .managedObjectModel
        let legacyModel = legacyModelWithoutIndexes(from: currentModel)
        let storeURL = temporaryStoreURL()
        defer {
            for url in sqliteStoreURLs(for: storeURL) {
                try? FileManager.default.removeItem(at: url)
            }
        }

        let legacyContainer = try loadContainer(model: legacyModel, storeURL: storeURL, migrates: false)
        try insertLegacyRecords(in: legacyContainer.viewContext)
        try legacyContainer.viewContext.save()
        try removeStores(from: legacyContainer)

        let migratedContainer = try loadContainer(model: currentModel, storeURL: storeURL, migrates: true)
        defer { try? removeStores(from: migratedContainer) }

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Bill")
        XCTAssertEqual(try migratedContainer.viewContext.count(for: request), 1)
    }

    @MainActor
    func testStoreLoadFailureMarksStartupAsFailed() {
        let startupState = PersistenceStartupState()

        _ = PersistenceController(
            inMemory: true,
            startupState: startupState,
            storeLoader: { _, completion in
                completion(TestPersistenceError.storeLoad)
            }
        )

        let issue = failedIssue(from: startupState.status)
        XCTAssertEqual(issue?.phase, .storeLoad)
    }

    @MainActor
    func testSeedMigrationFailureMarksStartupAsFailed() async throws {
        let startupState = PersistenceStartupState()

        _ = PersistenceController(
            inMemory: true,
            startupState: startupState,
            storeLoader: { _, completion in
                completion(nil)
            },
            seedRunner: { _ in
                throw TestPersistenceError.seed
            }
        )

        let issue = try await waitForFailedIssue(in: startupState)
        XCTAssertEqual(issue.phase, .seedMigration)
    }

    private func failedIssue(from status: PersistenceStartupStatus) -> PersistenceStartupIssue? {
        guard case .failed(let issue) = status else {
            return nil
        }
        return issue
    }

    @MainActor
    private func waitForFailedIssue(in startupState: PersistenceStartupState) async throws -> PersistenceStartupIssue {
        for _ in 0..<50 {
            if let issue = failedIssue(from: startupState.status) {
                return issue
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Expected persistence startup to fail")
        throw TestPersistenceError.timeout
    }

    private func entity(named name: String, in model: NSManagedObjectModel) throws -> NSEntityDescription {
        guard let entity = model.entitiesByName[name] else {
            throw TestPersistenceError.missingEntity(name)
        }
        return entity
    }

    private func indexedPropertyNames(for entity: NSEntityDescription) -> Set<String> {
        Set(entity.indexes.flatMap { index in
            index.elements.compactMap { $0.property?.name }
        })
    }

    private func uniquePropertyNameSets(for entity: NSEntityDescription) -> Set<Set<String>> {
        Set(entity.uniquenessConstraints.map { constraint in
            Set(constraint.compactMap { item -> String? in
                if let property = item as? NSPropertyDescription {
                    return property.name
                }
                return item as? String
            })
        })
    }

    private func legacyModelWithoutIndexes(from model: NSManagedObjectModel) -> NSManagedObjectModel {
        let legacyModel = model.copy() as! NSManagedObjectModel
        for entity in legacyModel.entities {
            entity.indexes = []
            entity.uniquenessConstraints = []
        }
        return legacyModel
    }

    private func temporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("Tally-\(UUID().uuidString)")
            .appendingPathExtension("sqlite")
    }

    private func sqliteStoreURLs(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]
    }

    private func loadContainer(
        model: NSManagedObjectModel,
        storeURL: URL,
        migrates: Bool
    ) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Tally", managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = migrates
        description.shouldInferMappingModelAutomatically = migrates
        container.persistentStoreDescriptions = [description]

        let semaphore = DispatchSemaphore(value: 0)
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }
        semaphore.wait()
        if let loadError {
            throw loadError
        }
        return container
    }

    private func removeStores(from container: NSPersistentContainer) throws {
        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
    }

    private func insertLegacyRecords(in context: NSManagedObjectContext) throws {
        let now = Date()
        let snapshot = TimePolicy.snapshot(for: now)
        let categoryID = UUID()

        let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
        category.setValue(categoryID, forKey: "id")
        category.setValue(BillType.expense.rawValue, forKey: "type")
        category.setValue("测试", forKey: "name")
        category.setValue("tag", forKey: "iconKey")
        category.setValue(Int64(0x13EC37), forKey: "colorHex")
        category.setValue(false, forKey: "isSystem")
        category.setValue(Int64(0), forKey: "sortOrder")

        let bill = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: context)
        bill.setValue(UUID(), forKey: "id")
        bill.setValue(BillType.expense.rawValue, forKey: "type")
        bill.setValue(Int64(1200), forKey: "amount")
        bill.setValue(snapshot.occurredAtUTC, forKey: "occurredAtUTC")
        bill.setValue(snapshot.tzId, forKey: "tzId")
        bill.setValue(Int32(snapshot.tzOffset), forKey: "tzOffset")
        bill.setValue(snapshot.occurredLocalDate, forKey: "occurredLocalDate")
        bill.setValue("旧库账单", forKey: "note")
        bill.setValue(categoryID, forKey: "categoryId")
        bill.setValue(false, forKey: "isFromRecurring")
        bill.setValue(now, forKey: "createdAt")
        bill.setValue(now, forKey: "updatedAt")

        let recurringTask = NSEntityDescription.insertNewObject(forEntityName: "RecurringTask", into: context)
        recurringTask.setValue(UUID(), forKey: "id")
        recurringTask.setValue(BillType.expense.rawValue, forKey: "type")
        recurringTask.setValue(Int64(1200), forKey: "amount")
        recurringTask.setValue(categoryID, forKey: "categoryId")
        recurringTask.setValue("旧库定时", forKey: "note")
        recurringTask.setValue(now, forKey: "firstDate")
        recurringTask.setValue(RepeatRule.daily.rawValue, forKey: "repeatRule")
        recurringTask.setValue(now, forKey: "nextFireDate")
        recurringTask.setValue(Int16(9), forKey: "hour")
        recurringTask.setValue(Int16(0), forKey: "minute")
        recurringTask.setValue(true, forKey: "isEnabled")
        recurringTask.setValue(now, forKey: "createdAt")
        recurringTask.setValue(now, forKey: "updatedAt")
    }
}

private enum TestPersistenceError: LocalizedError {
    case storeLoad
    case seed
    case timeout
    case missingEntity(String)

    var errorDescription: String? {
        switch self {
        case .storeLoad:
            return "Injected store load failure"
        case .seed:
            return "Injected seed failure"
        case .timeout:
            return "Timed out waiting for persistence status"
        case .missingEntity(let name):
            return "Missing entity \(name)"
        }
    }
}
