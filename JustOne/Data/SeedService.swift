import CoreData

struct SeedService {
    private struct SeedCategory {
        let id: UUID
        let type: BillType
        let name: String
        let iconKey: String
        let isSystem: Bool
        let sortOrder: Int
    }

    private let categories: [SeedCategory] = [
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, type: .expense, name: "未分类", iconKey: "questionmark", isSystem: true, sortOrder: 0),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, type: .income, name: "未分类", iconKey: "questionmark", isSystem: true, sortOrder: 0),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, type: .expense, name: "餐饮", iconKey: "fork.knife", isSystem: true, sortOrder: 1),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, type: .income, name: "工资", iconKey: "creditcard", isSystem: true, sortOrder: 1)
    ]

    func seedIfNeeded(in context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        fetchRequest.fetchLimit = 1
        let existingCount = try context.count(for: fetchRequest)
        guard existingCount == 0 else { return }

        for seed in categories {
            let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
            object.setValue(seed.id, forKey: "id")
            object.setValue(seed.type.rawValue, forKey: "type")
            object.setValue(seed.name, forKey: "name")
            object.setValue(seed.iconKey, forKey: "iconKey")
            object.setValue(seed.isSystem, forKey: "isSystem")
            object.setValue(Int64(seed.sortOrder), forKey: "sortOrder")
        }

        if context.hasChanges {
            try context.save()
        }
    }

    func seedPreviewBill(in context: NSManagedObjectContext) throws {
        let object = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: context)
        let now = Date()
        object.setValue(UUID(), forKey: "id")
        object.setValue(BillType.expense.rawValue, forKey: "type")
        object.setValue(Int64(428560), forKey: "amount")
        object.setValue(now, forKey: "occurredAtUTC")
        object.setValue(TimeZone.current.identifier, forKey: "tzId")
        object.setValue(Int32(TimeZone.current.secondsFromGMT(for: now)), forKey: "tzOffset")
        object.setValue(DayKeyFormatter.dayKey(for: now), forKey: "occurredLocalDate")
        object.setValue("示例账单", forKey: "note")
        object.setValue(false, forKey: "isFromRecurring")
        object.setValue(now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")

        if context.hasChanges {
            try context.save()
        }
    }
}
