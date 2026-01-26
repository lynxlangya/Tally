import CoreData
import Foundation

final class CoreDataRecurringRepository: RecurringRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func list() throws -> [RecurringTaskRecord] {
        try context.performAndWaitThrowing {
            let request = NSFetchRequest<NSManagedObject>(entityName: "RecurringTask")
            request.sortDescriptors = [NSSortDescriptor(key: "nextFireDate", ascending: true)]
            let objects = try context.fetch(request)
            return try objects.map { try mapRecurring(from: $0) }
        }
    }

    func create(_ record: RecurringTaskRecord) throws {
        try context.performAndWaitThrowing {
            let object = NSEntityDescription.insertNewObject(forEntityName: "RecurringTask", into: context)
            apply(record, to: object)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func update(_ record: RecurringTaskRecord) throws {
        try context.performAndWaitThrowing {
            let object = try fetchRecurringObject(id: record.id)
            apply(record, to: object)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func delete(id: UUID) throws {
        try context.performAndWaitThrowing {
            let object = try fetchRecurringObject(id: id)
            context.delete(object)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    func setEnabled(id: UUID, isEnabled: Bool) throws {
        try context.performAndWaitThrowing {
            let object = try fetchRecurringObject(id: id)
            object.setValue(isEnabled, forKey: "isEnabled")
            object.setValue(Date(), forKey: "updatedAt")
            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func fetchRecurringObject(id: UUID) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "RecurringTask")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let objects = try context.fetch(request)
        guard let object = objects.first else { throw RepositoryError.notFound }
        return object
    }

    private func apply(_ record: RecurringTaskRecord, to object: NSManagedObject) {
        object.setValue(record.id, forKey: "id")
        object.setValue(record.type.rawValue, forKey: "type")
        object.setValue(Int64(record.amount.cents), forKey: "amount")
        object.setValue(record.categoryId, forKey: "categoryId")
        object.setValue(record.note, forKey: "note")
        object.setValue(record.firstDate, forKey: "firstDate")
        object.setValue(record.repeatRule, forKey: "repeatRule")
        object.setValue(record.nextFireDate, forKey: "nextFireDate")
        object.setValue(Int16(record.hour), forKey: "hour")
        object.setValue(Int16(record.minute), forKey: "minute")
        object.setValue(record.lastRunAtUTC, forKey: "lastRunAtUTC")
        object.setValue(record.isEnabled, forKey: "isEnabled")
        object.setValue(record.createdAt, forKey: "createdAt")
        object.setValue(record.updatedAt, forKey: "updatedAt")
    }

    private func mapRecurring(from object: NSManagedObject) throws -> RecurringTaskRecord {
        guard let id = object.value(forKey: "id") as? UUID else { throw RepositoryError.invalidData(field: "RecurringTask.id") }
        guard let typeRaw = object.value(forKey: "type") as? String,
              let type = BillType(rawValue: typeRaw) else { throw RepositoryError.invalidData(field: "RecurringTask.type") }
        guard let amountValue = object.value(forKey: "amount") as? Int64,
              let amountInt = Int(exactly: amountValue) else { throw RepositoryError.invalidData(field: "RecurringTask.amount") }
        guard let hourValue = object.value(forKey: "hour") as? Int16 else { throw RepositoryError.invalidData(field: "RecurringTask.hour") }
        guard let minuteValue = object.value(forKey: "minute") as? Int16 else { throw RepositoryError.invalidData(field: "RecurringTask.minute") }
        guard let isEnabled = object.value(forKey: "isEnabled") as? Bool else { throw RepositoryError.invalidData(field: "RecurringTask.isEnabled") }
        guard let createdAt = object.value(forKey: "createdAt") as? Date else { throw RepositoryError.invalidData(field: "RecurringTask.createdAt") }
        guard let updatedAt = object.value(forKey: "updatedAt") as? Date else { throw RepositoryError.invalidData(field: "RecurringTask.updatedAt") }

        let categoryId = object.value(forKey: "categoryId") as? UUID
        let note = object.value(forKey: "note") as? String
        let lastRunAtUTC = object.value(forKey: "lastRunAtUTC") as? Date
        let firstDate = object.value(forKey: "firstDate") as? Date ?? createdAt
        let repeatRule = object.value(forKey: "repeatRule") as? String ?? RepeatRule.daily.rawValue
        let nextFireDate = object.value(forKey: "nextFireDate") as? Date ?? firstDate

        return RecurringTaskRecord(
            id: id,
            type: type,
            amount: Money(cents: amountInt),
            categoryId: categoryId,
            note: note,
            firstDate: firstDate,
            repeatRule: repeatRule,
            nextFireDate: nextFireDate,
            hour: Int(hourValue),
            minute: Int(minuteValue),
            lastRunAtUTC: lastRunAtUTC,
            isEnabled: isEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
