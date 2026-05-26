import Foundation

protocol ImportWriteRepository {
    func importBackup(
        categories: [BackupImportCategory],
        bills: [BackupImportBill],
        recurringTasks: [BackupImportRecurringTask]
    ) throws -> ImportWriteResult
}

struct BackupImportCategory {
    let id: UUID
    let type: BillType
    let name: String
    let iconKey: String
    let colorHex: Int?
    let sortOrder: Int
}

struct BackupImportBill {
    let id: UUID
    let type: BillType
    let amountCents: Int
    let occurredAtUTC: Date
    let occurredLocalDate: String
    let tzId: String
    let tzOffset: Int
    let note: String?
    let categoryId: UUID
    let isFromRecurring: Bool
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let trashUntil: Date?
}

struct BackupImportRecurringTask {
    let id: UUID
    let type: BillType
    let amountCents: Int
    let categoryId: UUID
    let note: String?
    let firstDate: Date
    let repeatRule: String
    let nextFireDate: Date
    let hour: Int
    let minute: Int
    let lastRunAtUTC: Date?
    let isEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct ImportWriteResult {
    let importedCount: Int
    let skippedCount: Int
}
