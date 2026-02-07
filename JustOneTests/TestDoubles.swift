import Foundation
@testable import JustOne

final class InMemoryRecurringRepository: RecurringRepository {
    private(set) var tasks: [RecurringTaskRecord]
    private(set) var updatedTasks: [RecurringTaskRecord] = []

    init(tasks: [RecurringTaskRecord]) {
        self.tasks = tasks
    }

    func list() throws -> [RecurringTaskRecord] {
        tasks
    }

    func create(_ record: RecurringTaskRecord) throws {
        tasks.append(record)
    }

    func update(_ record: RecurringTaskRecord) throws {
        if let index = tasks.firstIndex(where: { $0.id == record.id }) {
            tasks[index] = record
        } else {
            tasks.append(record)
        }
        updatedTasks.append(record)
    }

    func delete(id: UUID) throws {
        tasks.removeAll { $0.id == id }
    }

    func setEnabled(id: UUID, isEnabled: Bool) throws {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let original = tasks[index]
        tasks[index] = RecurringTaskRecord(
            id: original.id,
            type: original.type,
            amount: original.amount,
            categoryId: original.categoryId,
            note: original.note,
            firstDate: original.firstDate,
            repeatRule: original.repeatRule,
            nextFireDate: original.nextFireDate,
            hour: original.hour,
            minute: original.minute,
            lastRunAtUTC: original.lastRunAtUTC,
            isEnabled: isEnabled,
            createdAt: original.createdAt,
            updatedAt: original.updatedAt
        )
    }
}

final class InMemoryBillRepository: BillRepository {
    private(set) var records: [BillRecord]
    private(set) var createdDrafts: [BillDraft] = []

    init(records: [BillRecord] = []) {
        self.records = records
    }

    func create(_ draft: BillDraft) throws -> BillRecord {
        createdDrafts.append(draft)
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
        records.append(record)
        return record
    }

    func update(_ record: BillRecord) throws -> BillRecord {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        return record
    }

    func fetch(by dayKey: String) throws -> [BillRecord] {
        records.filter { $0.occurredLocalDate == dayKey }
    }

    func list() throws -> [BillRecord] {
        records
    }

    func list(fromDayKey: String, toDayKey: String, type: BillType?) throws -> [BillRecord] {
        records.filter { record in
            let withinRange = record.occurredLocalDate >= fromDayKey && record.occurredLocalDate <= toDayKey
            let typeMatches = type == nil || record.type == type
            return withinRange && typeMatches
        }
    }

    func list(monthKey: String, type: BillType?) throws -> [BillRecord] {
        records.filter { record in
            let monthMatches = record.occurredLocalDate.hasPrefix(monthKey)
            let typeMatches = type == nil || record.type == type
            return monthMatches && typeMatches
        }
    }

    func listYears() throws -> [Int] {
        let years = records.compactMap { record -> Int? in
            guard record.occurredLocalDate.count >= 4 else { return nil }
            return Int(record.occurredLocalDate.prefix(4))
        }
        return Array(Set(years)).sorted()
    }

    func softDelete(id: UUID, deletedAt: Date, trashUntil: Date) throws {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        let original = records[index]
        records[index] = BillRecord(
            id: original.id,
            type: original.type,
            amount: original.amount,
            occurredAtUTC: original.occurredAtUTC,
            tzId: original.tzId,
            tzOffset: original.tzOffset,
            occurredLocalDate: original.occurredLocalDate,
            note: original.note,
            categoryId: original.categoryId,
            isFromRecurring: original.isFromRecurring,
            createdAt: original.createdAt,
            updatedAt: deletedAt,
            deletedAt: deletedAt,
            trashUntil: trashUntil
        )
    }

    func restore(id: UUID) throws {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        let original = records[index]
        records[index] = BillRecord(
            id: original.id,
            type: original.type,
            amount: original.amount,
            occurredAtUTC: original.occurredAtUTC,
            tzId: original.tzId,
            tzOffset: original.tzOffset,
            occurredLocalDate: original.occurredLocalDate,
            note: original.note,
            categoryId: original.categoryId,
            isFromRecurring: original.isFromRecurring,
            createdAt: original.createdAt,
            updatedAt: Date(),
            deletedAt: nil,
            trashUntil: nil
        )
    }

    func purgeExpired(asOf date: Date) throws {
        records.removeAll { record in
            guard let trashUntil = record.trashUntil else { return false }
            return trashUntil <= date
        }
    }
}
