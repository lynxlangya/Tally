import Foundation

final class MockBillRepository: BillRepository {
    private var storage: [UUID: BillRecord]

    init(seed: [BillRecord] = []) {
        var map: [UUID: BillRecord] = [:]
        seed.forEach { map[$0.id] = $0 }
        self.storage = map
    }

    func create(_ draft: BillDraft) throws -> BillRecord {
        let snapshot = TimePolicy.snapshot(for: draft.occurredAtLocal)
        let now = Date()
        let record = BillRecord(
            id: UUID(),
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
        storage[record.id] = record
        return record
    }

    func update(_ record: BillRecord) throws -> BillRecord {
        guard storage[record.id] != nil else { throw RepositoryError.notFound }
        storage[record.id] = record
        return record
    }

    func fetch(by dayKey: String) throws -> [BillRecord] {
        storage.values
            .filter { $0.occurredLocalDate == dayKey && $0.deletedAt == nil }
            .sorted { $0.occurredAtUTC > $1.occurredAtUTC }
    }

    func list() throws -> [BillRecord] {
        storage.values
            .filter { $0.deletedAt == nil }
            .sorted { $0.occurredAtUTC > $1.occurredAtUTC }
    }

    func softDelete(id: UUID, deletedAt: Date, trashUntil: Date) throws {
        guard let record = storage[id] else { throw RepositoryError.notFound }
        let updated = BillRecord(
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
            updatedAt: record.updatedAt,
            deletedAt: deletedAt,
            trashUntil: trashUntil
        )
        storage[id] = updated
    }

    func restore(id: UUID) throws {
        guard let record = storage[id] else { throw RepositoryError.notFound }
        let updated = BillRecord(
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
            updatedAt: record.updatedAt,
            deletedAt: nil,
            trashUntil: nil
        )
        storage[id] = updated
    }

    func purgeExpired(asOf date: Date) throws {
        let expiredIds = storage.values
            .filter { ($0.trashUntil ?? Date.distantFuture) < date }
            .map { $0.id }
        expiredIds.forEach { storage.removeValue(forKey: $0) }
    }
}

final class MockCategoryRepository: CategoryRepository {
    private var storage: [UUID: CategoryRecord]

    init(seed: [CategoryRecord] = []) {
        var map: [UUID: CategoryRecord] = [:]
        seed.forEach { map[$0.id] = $0 }
        storage = map
    }

    func list(type: BillType) throws -> [CategoryRecord] {
        storage.values
            .filter { $0.type == type }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func create(_ record: CategoryRecord) throws {
        storage[record.id] = record
    }

    func delete(id: UUID, migrateTo destinationId: UUID) throws {
        storage.removeValue(forKey: id)
    }

    func count(type: BillType) throws -> Int {
        storage.values.filter { $0.type == type }.count
    }
}

final class NoopCategoryRepository: CategoryRepository {
    func list(type: BillType) throws -> [CategoryRecord] { [] }
    func create(_ record: CategoryRecord) throws {}
    func delete(id: UUID, migrateTo destinationId: UUID) throws {}
    func count(type: BillType) throws -> Int { 0 }
}

final class NoopRecurringRepository: RecurringRepository {
    func list() throws -> [RecurringTaskRecord] { [] }
    func create(_ record: RecurringTaskRecord) throws {}
    func update(_ record: RecurringTaskRecord) throws {}
    func delete(id: UUID) throws {}
    func setEnabled(id: UUID, isEnabled: Bool) throws {}
}

final class NoopTrashRepository: TrashRepository {
    func list() throws -> [BillRecord] { [] }
    func restore(id: UUID) throws {}
    func deleteForever(id: UUID) throws {}
    func clearAll() throws {}
}
