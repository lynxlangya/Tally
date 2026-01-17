import Foundation

protocol BillRepository {
    func create(_ draft: BillDraft) throws -> BillRecord
    func update(_ record: BillRecord) throws -> BillRecord
    func fetch(by dayKey: String) throws -> [BillRecord]
    func list() throws -> [BillRecord]
    func softDelete(id: UUID, deletedAt: Date, trashUntil: Date) throws
    func restore(id: UUID) throws
    func purgeExpired(asOf date: Date) throws
}

protocol CategoryRepository {
    func list(type: BillType) throws -> [CategoryRecord]
    func create(_ record: CategoryRecord) throws
    func delete(id: UUID, migrateTo destinationId: UUID) throws
    func count(type: BillType) throws -> Int
}

protocol RecurringRepository {
    func list() throws -> [RecurringTaskRecord]
    func create(_ record: RecurringTaskRecord) throws
    func update(_ record: RecurringTaskRecord) throws
    func delete(id: UUID) throws
    func setEnabled(id: UUID, isEnabled: Bool) throws
}

protocol TrashRepository {
    func list() throws -> [BillRecord]
    func restore(id: UUID) throws
    func deleteForever(id: UUID) throws
    func clearAll() throws
}
