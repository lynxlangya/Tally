import CoreData

enum BillRecordMapper {
    static func map(from object: NSManagedObject) throws -> BillRecord {
        guard let id = object.value(forKey: "id") as? UUID else { throw RepositoryError.invalidData(field: "Bill.id") }
        guard let typeRaw = object.value(forKey: "type") as? String,
              let type = BillType(rawValue: typeRaw) else { throw RepositoryError.invalidData(field: "Bill.type") }
        guard let amountValue = object.value(forKey: "amount") as? Int64,
              let amountInt = Int(exactly: amountValue) else { throw RepositoryError.invalidData(field: "Bill.amount") }
        guard let occurredAtUTC = object.value(forKey: "occurredAtUTC") as? Date else { throw RepositoryError.invalidData(field: "Bill.occurredAtUTC") }
        guard let tzId = object.value(forKey: "tzId") as? String else { throw RepositoryError.invalidData(field: "Bill.tzId") }
        guard let tzOffsetValue = object.value(forKey: "tzOffset") as? Int32 else { throw RepositoryError.invalidData(field: "Bill.tzOffset") }
        guard let occurredLocalDate = object.value(forKey: "occurredLocalDate") as? String else { throw RepositoryError.invalidData(field: "Bill.occurredLocalDate") }
        guard let isFromRecurring = object.value(forKey: "isFromRecurring") as? Bool else { throw RepositoryError.invalidData(field: "Bill.isFromRecurring") }
        guard let createdAt = object.value(forKey: "createdAt") as? Date else { throw RepositoryError.invalidData(field: "Bill.createdAt") }
        guard let updatedAt = object.value(forKey: "updatedAt") as? Date else { throw RepositoryError.invalidData(field: "Bill.updatedAt") }

        let note = object.value(forKey: "note") as? String
        let categoryId = object.value(forKey: "categoryId") as? UUID
        let deletedAt = object.value(forKey: "deletedAt") as? Date
        let trashUntil = object.value(forKey: "trashUntil") as? Date

        return BillRecord(
            id: id,
            type: type,
            amount: Money(cents: amountInt),
            occurredAtUTC: occurredAtUTC,
            tzId: tzId,
            tzOffset: Int(tzOffsetValue),
            occurredLocalDate: occurredLocalDate,
            note: note,
            categoryId: categoryId,
            isFromRecurring: isFromRecurring,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            trashUntil: trashUntil
        )
    }
}
