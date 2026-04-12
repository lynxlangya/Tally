import CoreData
import XCTest
@testable import JustOne

final class CoreDataImportWriteRepositoryTests: XCTestCase {
    @MainActor
    func testImportBackupPersistsCategoriesBillsAndRecurringTasks() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        try CoreDataSeedService(context: context).seedIfNeeded()
        let repository = CoreDataImportWriteRepository(context: context)

        let categoryId = UUID()
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let result = try repository.importBackup(
            categories: [
                BackupImportCategory(
                    id: categoryId,
                    type: .expense,
                    name: "测试分类",
                    iconKey: "fork.knife",
                    colorHex: 0x13EC37,
                    sortOrder: 99
                )
            ],
            bills: [
                BackupImportBill(
                    id: UUID(),
                    type: .expense,
                    amountCents: 1_234,
                    occurredAtUTC: now,
                    occurredLocalDate: "2026-04-12",
                    tzId: "Asia/Shanghai",
                    tzOffset: 28_800,
                    note: "午餐",
                    categoryId: categoryId,
                    isFromRecurring: false,
                    createdAt: now,
                    updatedAt: now,
                    deletedAt: nil,
                    trashUntil: nil
                )
            ],
            recurringTasks: [
                BackupImportRecurringTask(
                    id: UUID(),
                    type: .expense,
                    amountCents: 1_234,
                    categoryId: categoryId,
                    note: "订阅",
                    firstDate: now,
                    repeatRule: RepeatRule.daily.rawValue,
                    nextFireDate: now.addingTimeInterval(3_600),
                    hour: 11,
                    minute: 0,
                    lastRunAtUTC: nil,
                    isEnabled: true,
                    createdAt: now,
                    updatedAt: now
                )
            ]
        )

        XCTAssertEqual(result.importedCount, 3)
        XCTAssertEqual(result.skippedCount, 0)
        let categoryRequest = NSFetchRequest<NSManagedObject>(entityName: "Category")
        let categories = try context.fetch(categoryRequest)
        XCTAssertTrue(categories.contains(where: { ($0.value(forKey: "id") as? UUID) == categoryId }))

        let billRequest = NSFetchRequest<NSManagedObject>(entityName: "Bill")
        let bills = try context.fetch(billRequest)
        XCTAssertEqual(bills.count, 1)
        XCTAssertEqual(bills.first?.value(forKey: "categoryId") as? UUID, categoryId)

        let recurringRequest = NSFetchRequest<NSManagedObject>(entityName: "RecurringTask")
        let recurringTasks = try context.fetch(recurringRequest)
        XCTAssertEqual(recurringTasks.count, 1)
        XCTAssertEqual(recurringTasks.first?.value(forKey: "categoryId") as? UUID, categoryId)
    }

    @MainActor
    func testImportBackupRollsBackWhenParentSaveFails() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = FailingSaveManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistence.container.persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        try CoreDataSeedService(context: context).seedIfNeeded()
        context.shouldFailOnSave = true

        let repository = CoreDataImportWriteRepository(context: context)
        let categoryId = UUID()

        XCTAssertThrowsError(
            try repository.importBackup(
                categories: [
                    BackupImportCategory(
                        id: categoryId,
                        type: .expense,
                        name: "会回滚的分类",
                        iconKey: "fork.knife",
                        colorHex: nil,
                        sortOrder: 10
                    )
                ],
                bills: [],
                recurringTasks: []
            )
        )

        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        let categories = try context.fetch(request)
        XCTAssertFalse(categories.contains(where: { ($0.value(forKey: "id") as? UUID) == categoryId }))
    }
}

private extension CoreDataImportWriteRepositoryTests {
    func fixedDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: 0
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}

private final class FailingSaveManagedObjectContext: NSManagedObjectContext, @unchecked Sendable {
    var shouldFailOnSave = false

    override func save() throws {
        if shouldFailOnSave {
            throw MockCoreDataSaveError.failed
        }
        try super.save()
    }
}

private enum MockCoreDataSaveError: LocalizedError {
    case failed

    var errorDescription: String? { "mock core data save failed" }
}
