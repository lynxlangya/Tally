import Foundation

struct BillDraft: Equatable, Codable {
    let type: BillType
    let amount: Money
    let occurredAtLocal: Date
    let note: String?
    let categoryId: UUID?
    let isFromRecurring: Bool
}

struct BillRecord: Identifiable, Equatable, Codable {
    let id: UUID
    let type: BillType
    let amount: Money
    let occurredAtUTC: Date
    let tzId: String
    let tzOffset: Int
    let occurredLocalDate: String
    let note: String?
    let categoryId: UUID?
    let isFromRecurring: Bool
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let trashUntil: Date?
}

struct CategoryRecord: Identifiable, Equatable, Codable {
    let id: UUID
    let type: BillType
    let name: String
    let iconKey: String
    let colorHex: Int?
    let isSystem: Bool
    let sortOrder: Int
}

struct RecurringTaskRecord: Identifiable, Equatable, Codable {
    let id: UUID
    let type: BillType
    let amount: Money
    let categoryId: UUID?
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
