import CoreData

struct CoreDataSeedService: SeedService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    private struct SeedCategory {
        let id: UUID
        let type: BillType
        let name: String
        let iconKey: String
        let colorHex: Int
        let isSystem: Bool
        let sortOrder: Int
    }

    private let categories: [SeedCategory] = [
        SeedCategory(id: SystemCategoryID.uncategorizedExpense, type: .expense, name: "未分类", iconKey: "questionmark", colorHex: 0x13EC37, isSystem: true, sortOrder: 0),
        SeedCategory(id: SystemCategoryID.uncategorizedIncome, type: .income, name: "未分类", iconKey: "questionmark", colorHex: 0x13EC37, isSystem: true, sortOrder: 0),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, type: .expense, name: "餐饮", iconKey: "fork.knife", colorHex: 0xF97316, isSystem: false, sortOrder: 1),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, type: .income, name: "工资", iconKey: "creditcard", colorHex: 0x3B82F6, isSystem: false, sortOrder: 1)
    ]

    func seedIfNeeded() throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        fetchRequest.fetchLimit = 1
        let existingCount = try context.count(for: fetchRequest)
        if existingCount == 0 {
            for seed in categories {
                let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
                apply(seed, to: object)
            }
        } else {
            try ensureSystemCategories()
        }

        if context.hasChanges {
            try context.save()
        }
    }

    func seedPreviewBill() throws {
        let object = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: context)
        let now = Date()
        let snapshot = TimePolicy.snapshot(for: now)
        object.setValue(UUID(), forKey: "id")
        object.setValue(BillType.expense.rawValue, forKey: "type")
        object.setValue(Int64(428560), forKey: "amount")
        object.setValue(snapshot.occurredAtUTC, forKey: "occurredAtUTC")
        object.setValue(snapshot.tzId, forKey: "tzId")
        object.setValue(Int32(snapshot.tzOffset), forKey: "tzOffset")
        object.setValue(snapshot.occurredLocalDate, forKey: "occurredLocalDate")
        object.setValue("示例账单", forKey: "note")
        object.setValue(false, forKey: "isFromRecurring")
        object.setValue(now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")

        if context.hasChanges {
            try context.save()
        }
    }

    private func ensureSystemCategories() throws {
        let systemSeeds = categories.filter { $0.isSystem }
        for seed in systemSeeds {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", seed.id as CVarArg)
            let objects = try context.fetch(request)
            let object = objects.first ?? NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
            apply(seed, to: object)
        }
    }

    private func apply(_ seed: SeedCategory, to object: NSManagedObject) {
        object.setValue(seed.id, forKey: "id")
        object.setValue(seed.type.rawValue, forKey: "type")
        object.setValue(seed.name, forKey: "name")
        object.setValue(seed.iconKey, forKey: "iconKey")
        object.setValue(Int64(seed.colorHex), forKey: "colorHex")
        object.setValue(seed.isSystem, forKey: "isSystem")
        object.setValue(Int64(seed.sortOrder), forKey: "sortOrder")
    }
}
