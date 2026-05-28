import CoreData
import Foundation

struct CoreDataImportWriteRepository: ImportWriteRepository {
    private let makeBackgroundContext: () -> NSManagedObjectContext

    init(container: NSPersistentContainer) {
        self.makeBackgroundContext = {
            container.newBackgroundContext()
        }
    }

    init(makeBackgroundContext: @escaping () -> NSManagedObjectContext) {
        self.makeBackgroundContext = makeBackgroundContext
    }

    func importBackup(
        categories: [BackupImportCategory],
        bills: [BackupImportBill],
        recurringTasks: [BackupImportRecurringTask]
    ) async throws -> ImportWriteResult {
        try await performImport(categories: categories, bills: bills, recurringTasks: recurringTasks)
    }

    func importBills(_ bills: [BackupImportBill]) async throws -> ImportWriteResult {
        try await performImport(categories: [], bills: bills, recurringTasks: [])
    }

    private func performImport(
        categories: [BackupImportCategory],
        bills: [BackupImportBill],
        recurringTasks: [BackupImportRecurringTask]
    ) async throws -> ImportWriteResult {
        let context = makeBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return try await context.perform {
            do {
                return try Self.importRecords(
                    categories: categories,
                    bills: bills,
                    recurringTasks: recurringTasks,
                    in: context
                )
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    private static func importRecords(
        categories: [BackupImportCategory],
        bills: [BackupImportBill],
        recurringTasks: [BackupImportRecurringTask],
        in context: NSManagedObjectContext
    ) throws -> ImportWriteResult {
        var importedCount = 0
        var skippedCount = 0

        var categoryObjects = try fetchManagedObjectMap(entityName: "Category", context: context)
        for category in categories {
            if let object = categoryObjects[category.id] {
                let isSystem = object.value(forKey: "isSystem") as? Bool ?? false
                if isSystem {
                    skippedCount += 1
                    continue
                }
                apply(category: category, to: object)
                importedCount += 1
            } else {
                let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
                apply(category: category, to: object)
                categoryObjects[category.id] = object
                importedCount += 1
            }
        }

        let categoryIDs = Set(categoryObjects.keys)

        let billObjects = try fetchManagedObjectMap(entityName: "Bill", context: context)
        for bill in bills {
            if billObjects[bill.id] != nil {
                skippedCount += 1
                continue
            }
            let object = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: context)
            let resolvedCategoryID = categoryIDs.contains(bill.categoryId)
                ? bill.categoryId
                : SystemCategoryID.uncategorized(for: bill.type)
            apply(bill: bill, resolvedCategoryID: resolvedCategoryID, to: object)
            importedCount += 1
        }

        var recurringObjects = try fetchManagedObjectMap(entityName: "RecurringTask", context: context)
        for recurring in recurringTasks {
            if let object = recurringObjects[recurring.id] {
                apply(recurring: recurring, to: object)
                importedCount += 1
            } else {
                let object = NSEntityDescription.insertNewObject(forEntityName: "RecurringTask", into: context)
                apply(recurring: recurring, to: object)
                recurringObjects[recurring.id] = object
                importedCount += 1
            }
        }

        if context.hasChanges {
            try context.save()
        }

        return ImportWriteResult(importedCount: importedCount, skippedCount: skippedCount)
    }

    private static func fetchManagedObjectMap(
        entityName: String,
        context: NSManagedObjectContext
    ) throws -> [UUID: NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let objects = try context.fetch(request)
        var result: [UUID: NSManagedObject] = [:]
        for object in objects {
            if let id = object.value(forKey: "id") as? UUID {
                result[id] = object
            }
        }
        return result
    }

    private static func apply(category: BackupImportCategory, to object: NSManagedObject) {
        object.setValue(category.id, forKey: "id")
        object.setValue(category.type.rawValue, forKey: "type")
        object.setValue(category.name, forKey: "name")
        object.setValue(category.iconKey, forKey: "iconKey")
        object.setValue(category.colorHex.map { Int64($0) }, forKey: "colorHex")
        object.setValue(false, forKey: "isSystem")
        object.setValue(Int64(category.sortOrder), forKey: "sortOrder")
    }

    private static func apply(bill: BackupImportBill, resolvedCategoryID: UUID, to object: NSManagedObject) {
        object.setValue(bill.id, forKey: "id")
        object.setValue(bill.type.rawValue, forKey: "type")
        object.setValue(Int64(bill.amountCents), forKey: "amount")
        object.setValue(bill.occurredAtUTC, forKey: "occurredAtUTC")
        object.setValue(bill.tzId, forKey: "tzId")
        object.setValue(Int32(bill.tzOffset), forKey: "tzOffset")
        object.setValue(bill.occurredLocalDate, forKey: "occurredLocalDate")
        object.setValue(bill.note, forKey: "note")
        object.setValue(resolvedCategoryID, forKey: "categoryId")
        object.setValue(bill.isFromRecurring, forKey: "isFromRecurring")
        object.setValue(bill.createdAt, forKey: "createdAt")
        object.setValue(bill.updatedAt, forKey: "updatedAt")
        object.setValue(bill.deletedAt, forKey: "deletedAt")
        object.setValue(bill.trashUntil, forKey: "trashUntil")
    }

    private static func apply(recurring: BackupImportRecurringTask, to object: NSManagedObject) {
        object.setValue(recurring.id, forKey: "id")
        object.setValue(recurring.type.rawValue, forKey: "type")
        object.setValue(Int64(recurring.amountCents), forKey: "amount")
        object.setValue(recurring.categoryId, forKey: "categoryId")
        object.setValue(recurring.note, forKey: "note")
        object.setValue(recurring.firstDate, forKey: "firstDate")
        object.setValue(recurring.repeatRule, forKey: "repeatRule")
        object.setValue(recurring.nextFireDate, forKey: "nextFireDate")
        object.setValue(Int16(recurring.hour), forKey: "hour")
        object.setValue(Int16(recurring.minute), forKey: "minute")
        object.setValue(recurring.lastRunAtUTC, forKey: "lastRunAtUTC")
        object.setValue(recurring.isEnabled, forKey: "isEnabled")
        object.setValue(recurring.createdAt, forKey: "createdAt")
        object.setValue(recurring.updatedAt, forKey: "updatedAt")
    }
}
