import CoreData

final class CoreDataCategoryRepository: CategoryRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func list(type: BillType) throws -> [CategoryRecord] {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
            request.predicate = NSPredicate(format: "type == %@", type.rawValue)
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            let objects = try context.fetch(request)
            return try objects.map { try mapCategory(from: $0) }
        }
    }

    func create(_ record: CategoryRecord) throws {
        try context.performAndWaitThrowing {
            let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
            object.setValue(record.id, forKey: "id")
            object.setValue(record.type.rawValue, forKey: "type")
            object.setValue(record.name, forKey: "name")
            object.setValue(record.iconKey, forKey: "iconKey")
            object.setValue(record.isSystem, forKey: "isSystem")
            object.setValue(Int64(record.sortOrder), forKey: "sortOrder")

            if context.hasChanges {
                try context.save()
            }
        }
    }

    func delete(id: UUID, migrateTo destinationId: UUID) throws {
        try context.performAndWaitThrowing {
            let billRequest = NSFetchRequest<NSManagedObject>(entityName: "Bill")
            billRequest.predicate = NSPredicate(format: "categoryId == %@", id as CVarArg)
            let bills = try context.fetch(billRequest)
            for bill in bills {
                bill.setValue(destinationId, forKey: "categoryId")
            }

            let category = try fetchCategoryObject(id: id)
            context.delete(category)

            if context.hasChanges {
                try context.save()
            }
        }
    }

    func count(type: BillType) throws -> Int {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
            request.predicate = NSPredicate(format: "type == %@", type.rawValue)
            return try context.count(for: request)
        }
    }

    private func fetchCategoryObject(id: UUID) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let objects = try context.fetch(request)
        guard let object = objects.first else { throw RepositoryError.notFound }
        return object
    }

    private func mapCategory(from object: NSManagedObject) throws -> CategoryRecord {
        guard let id = object.value(forKey: "id") as? UUID else { throw RepositoryError.invalidData(field: "Category.id") }
        guard let typeRaw = object.value(forKey: "type") as? String,
              let type = BillType(rawValue: typeRaw) else { throw RepositoryError.invalidData(field: "Category.type") }
        guard let name = object.value(forKey: "name") as? String else { throw RepositoryError.invalidData(field: "Category.name") }
        guard let iconKey = object.value(forKey: "iconKey") as? String else { throw RepositoryError.invalidData(field: "Category.iconKey") }
        guard let isSystem = object.value(forKey: "isSystem") as? Bool else { throw RepositoryError.invalidData(field: "Category.isSystem") }
        guard let sortOrderValue = object.value(forKey: "sortOrder") as? Int64,
              let sortOrder = Int(exactly: sortOrderValue) else { throw RepositoryError.invalidData(field: "Category.sortOrder") }

        return CategoryRecord(
            id: id,
            type: type,
            name: name,
            iconKey: iconKey,
            isSystem: isSystem,
            sortOrder: sortOrder
        )
    }
}
