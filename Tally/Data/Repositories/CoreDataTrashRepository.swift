import CoreData

final class CoreDataTrashRepository: TrashRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func list() throws -> [BillRecord] {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Bill")
            request.predicate = NSPredicate(format: "deletedAt != nil")
            request.sortDescriptors = [NSSortDescriptor(key: "deletedAt", ascending: false)]
            let objects = try context.fetch(request)
            return try objects.map { try BillRecordMapper.map(from: $0) }
        }
    }

    func restore(id: UUID) throws {
        try context.performAndWaitThrowing {
            let object = try fetchBillObject(id: id)
            object.setValue(nil, forKey: "deletedAt")
            object.setValue(nil, forKey: "trashUntil")
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func deleteForever(id: UUID) throws {
        try context.performAndWaitThrowing {
            let object = try fetchBillObject(id: id)
            context.delete(object)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func clearAll() throws {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Bill")
            request.predicate = NSPredicate(format: "deletedAt != nil")
            let objects = try context.fetch(request)
            objects.forEach { context.delete($0) }
            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func fetchBillObject(id: UUID) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Bill")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let objects = try context.fetch(request)
        guard let object = objects.first else { throw RepositoryError.notFound }
        return object
    }
}
