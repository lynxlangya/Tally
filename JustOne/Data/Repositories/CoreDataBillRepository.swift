import CoreData

final class CoreDataBillRepository: BillRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func create(_ draft: BillDraft) throws -> BillRecord {
        try context.performAndWaitThrowing {
            let snapshot = TimePolicy.snapshot(for: draft.occurredAtLocal)
            let now = Date()
            let object = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: context)
            let id = UUID()

            object.setValue(id, forKey: "id")
            object.setValue(draft.type.rawValue, forKey: "type")
            object.setValue(Int64(draft.amount.cents), forKey: "amount")
            object.setValue(snapshot.occurredAtUTC, forKey: "occurredAtUTC")
            object.setValue(snapshot.tzId, forKey: "tzId")
            object.setValue(Int32(snapshot.tzOffset), forKey: "tzOffset")
            object.setValue(snapshot.occurredLocalDate, forKey: "occurredLocalDate")
            object.setValue(draft.note, forKey: "note")
            object.setValue(draft.categoryId, forKey: "categoryId")
            object.setValue(draft.isFromRecurring, forKey: "isFromRecurring")
            object.setValue(now, forKey: "createdAt")
            object.setValue(now, forKey: "updatedAt")
            object.setValue(nil, forKey: "deletedAt")
            object.setValue(nil, forKey: "trashUntil")

            if context.hasChanges {
                try context.save()
            }

            return BillRecord(
                id: id,
                type: draft.type,
                amount: draft.amount,
                occurredAtUTC: snapshot.occurredAtUTC,
                tzId: snapshot.tzId,
                tzOffset: snapshot.tzOffset,
                occurredLocalDate: snapshot.occurredLocalDate,
                note: draft.note,
                categoryId: draft.categoryId,
                isFromRecurring: draft.isFromRecurring,
                createdAt: now,
                updatedAt: now,
                deletedAt: nil,
                trashUntil: nil
            )
        }
    }

    func update(_ record: BillRecord) throws -> BillRecord {
        try context.performAndWaitThrowing {
            let object = try fetchBillObject(id: record.id)
            let updatedAt = Date()

            object.setValue(record.type.rawValue, forKey: "type")
            object.setValue(Int64(record.amount.cents), forKey: "amount")
            object.setValue(record.occurredAtUTC, forKey: "occurredAtUTC")
            object.setValue(record.tzId, forKey: "tzId")
            object.setValue(Int32(record.tzOffset), forKey: "tzOffset")
            object.setValue(record.occurredLocalDate, forKey: "occurredLocalDate")
            object.setValue(record.note, forKey: "note")
            object.setValue(record.categoryId, forKey: "categoryId")
            object.setValue(record.isFromRecurring, forKey: "isFromRecurring")
            object.setValue(record.createdAt, forKey: "createdAt")
            object.setValue(updatedAt, forKey: "updatedAt")
            object.setValue(record.deletedAt, forKey: "deletedAt")
            object.setValue(record.trashUntil, forKey: "trashUntil")

            if context.hasChanges {
                try context.save()
            }

            return BillRecord(
                id: record.id,
                type: record.type,
                amount: record.amount,
                occurredAtUTC: record.occurredAtUTC,
                tzId: record.tzId,
                tzOffset: record.tzOffset,
                occurredLocalDate: record.occurredLocalDate,
                note: record.note,
                categoryId: record.categoryId,
                isFromRecurring: record.isFromRecurring,
                createdAt: record.createdAt,
                updatedAt: updatedAt,
                deletedAt: record.deletedAt,
                trashUntil: record.trashUntil
            )
        }
    }

    func fetch(by dayKey: String) throws -> [BillRecord] {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Bill")
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "occurredLocalDate == %@", dayKey),
                NSPredicate(format: "deletedAt == nil")
            ])
            request.sortDescriptors = [NSSortDescriptor(key: "occurredAtUTC", ascending: false)]
            let objects = try context.fetch(request)
            return try objects.map { try BillRecordMapper.map(from: $0) }
        }
    }

    func list() throws -> [BillRecord] {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Bill")
            request.predicate = NSPredicate(format: "deletedAt == nil")
            request.sortDescriptors = [NSSortDescriptor(key: "occurredAtUTC", ascending: false)]
            let objects = try context.fetch(request)
            return try objects.map { try BillRecordMapper.map(from: $0) }
        }
    }

    func list(fromDayKey: String, toDayKey: String, type: BillType?) throws -> [BillRecord] {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Bill")
            var predicates: [NSPredicate] = [
                NSPredicate(format: "deletedAt == nil"),
                NSPredicate(format: "occurredLocalDate >= %@", fromDayKey),
                NSPredicate(format: "occurredLocalDate <= %@", toDayKey)
            ]
            if let type {
                predicates.append(NSPredicate(format: "type == %@", type.rawValue))
            }
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: "occurredAtUTC", ascending: false)]
            let objects = try context.fetch(request)
            return try objects.map { try BillRecordMapper.map(from: $0) }
        }
    }

    func list(monthKey: String, type: BillType?) throws -> [BillRecord] {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Bill")
            var predicates: [NSPredicate] = [
                NSPredicate(format: "deletedAt == nil"),
                NSPredicate(format: "occurredLocalDate BEGINSWITH %@", monthKey)
            ]
            if let type {
                predicates.append(NSPredicate(format: "type == %@", type.rawValue))
            }
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: "occurredAtUTC", ascending: false)]
            let objects = try context.fetch(request)
            return try objects.map { try BillRecordMapper.map(from: $0) }
        }
    }

    func listYears() throws -> [Int] {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSDictionary>(entityName: "Bill")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["occurredLocalDate"]
            request.returnsDistinctResults = true
            request.predicate = NSPredicate(format: "deletedAt == nil")
            let results = try context.fetch(request)
            let years = results.compactMap { dict -> Int? in
                guard let key = dict["occurredLocalDate"] as? String else { return nil }
                return Int(key.prefix(4))
            }
            return Array(Set(years)).sorted()
        }
    }

    func softDelete(id: UUID, deletedAt: Date, trashUntil: Date) throws {
        try context.performAndWaitThrowing {
            let object = try fetchBillObject(id: id)
            object.setValue(deletedAt, forKey: "deletedAt")
            object.setValue(trashUntil, forKey: "trashUntil")
            if context.hasChanges {
                try context.save()
            }
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

    func purgeExpired(asOf date: Date) throws {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Bill")
            request.predicate = NSPredicate(format: "trashUntil != nil AND trashUntil < %@", date as CVarArg)
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
