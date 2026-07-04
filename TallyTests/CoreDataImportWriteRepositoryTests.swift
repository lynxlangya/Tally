import CoreData
import XCTest
@testable import Tally

final class CoreDataImportWriteRepositoryTests: XCTestCase {
    @MainActor
    func testImportBackupPersistsCategoriesBillsAndRecurringTasks() async throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        try CoreDataSeedService(context: context).seedIfNeeded()
        let repository = CoreDataImportWriteRepository(container: persistence.container)

        let categoryId = UUID()
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let result = try await repository.importBackup(
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
    func testImportBackupSkipsSystemCategoryIDButKeepsBillReferenceInEmptyStore() async throws {
        let persistence = PersistenceController(inMemory: true, runsStartupSeed: false)
        let context = persistence.container.viewContext
        let repository = CoreDataImportWriteRepository(container: persistence.container)
        let systemCategoryId = SystemCategoryID.uncategorized(for: .expense)
        let billId = UUID()
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)

        let result = try await repository.importBackup(
            categories: [
                BackupImportCategory(
                    id: systemCategoryId,
                    type: .expense,
                    name: "未分类",
                    iconKey: "tag",
                    colorHex: nil,
                    sortOrder: 0
                )
            ],
            bills: [
                BackupImportBill(
                    id: billId,
                    type: .expense,
                    amountCents: 1_234,
                    occurredAtUTC: now,
                    occurredLocalDate: "2026-04-12",
                    tzId: "Asia/Shanghai",
                    tzOffset: 28_800,
                    note: "系统分类账单",
                    categoryId: systemCategoryId,
                    isFromRecurring: false,
                    createdAt: now,
                    updatedAt: now,
                    deletedAt: nil,
                    trashUntil: nil
                )
            ],
            recurringTasks: []
        )

        XCTAssertEqual(result.importedCount, 1)
        XCTAssertEqual(result.skippedCount, 1)

        let categoryRequest = NSFetchRequest<NSManagedObject>(entityName: "Category")
        categoryRequest.predicate = NSPredicate(format: "id == %@", systemCategoryId as CVarArg)
        let categories = try context.fetch(categoryRequest)
        XCTAssertTrue(categories.isEmpty)

        let billRequest = NSFetchRequest<NSManagedObject>(entityName: "Bill")
        billRequest.predicate = NSPredicate(format: "id == %@", billId as CVarArg)
        let bills = try context.fetch(billRequest)
        XCTAssertEqual(bills.count, 1)
        XCTAssertEqual(bills.first?.value(forKey: "categoryId") as? UUID, systemCategoryId)
    }

    @MainActor
    func testImportBillsSkipsExistingBillIDsAndImportsNewBills() async throws {
        let persistence = PersistenceController(inMemory: true, runsStartupSeed: false)
        let context = persistence.container.viewContext
        let repository = CoreDataImportWriteRepository(container: persistence.container)
        let now = fixedDate(year: 2026, month: 4, day: 12, hour: 10, minute: 0)
        let existingDuplicateID = UUID()
        let existingOtherID = UUID()
        let firstNewID = UUID()
        let secondNewID = UUID()

        let seedResult = try await repository.importBills([
            makeBill(id: existingDuplicateID, note: "已存在-会跳过", at: now),
            makeBill(id: existingOtherID, note: "已存在-保留", at: now)
        ])
        XCTAssertEqual(seedResult.importedCount, 2)
        XCTAssertEqual(seedResult.skippedCount, 0)

        let result = try await repository.importBills([
            makeBill(id: existingDuplicateID, note: "重复 ID", at: now),
            makeBill(id: firstNewID, note: "新账单 1", at: now),
            makeBill(id: secondNewID, note: "新账单 2", at: now)
        ])

        XCTAssertEqual(result.importedCount, 2)
        XCTAssertEqual(result.skippedCount, 1)

        let billRequest = NSFetchRequest<NSManagedObject>(entityName: "Bill")
        let bills = try context.fetch(billRequest)
        XCTAssertEqual(bills.count, 4)
        XCTAssertEqual(bills.filter { ($0.value(forKey: "id") as? UUID) == existingDuplicateID }.count, 1)
        let billIDs = Set(bills.compactMap { $0.value(forKey: "id") as? UUID })
        XCTAssertTrue(billIDs.isSuperset(of: [existingDuplicateID, existingOtherID, firstNewID, secondNewID]))
    }

    @MainActor
    func testImportBackupRollsBackWhenBackgroundSaveFails() async throws {
        let persistence = PersistenceController(inMemory: true)
        let viewContext = persistence.container.viewContext
        try CoreDataSeedService(context: viewContext).seedIfNeeded()
        let failingContext = FailingSaveManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        failingContext.persistentStoreCoordinator = persistence.container.persistentStoreCoordinator
        failingContext.shouldFailOnSave = true

        let repository = CoreDataImportWriteRepository(makeBackgroundContext: { failingContext })
        let categoryId = UUID()

        do {
            _ = try await repository.importBackup(
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
            XCTFail("expected background save to fail")
        } catch {
            // Expected: the background context rolls back all pending import objects.
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        let categories = try viewContext.fetch(request)
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

    func makeBill(id: UUID, note: String, at date: Date) -> BackupImportBill {
        BackupImportBill(
            id: id,
            type: .expense,
            amountCents: 1_234,
            occurredAtUTC: date,
            occurredLocalDate: DayKeyFormatter.dayKey(for: date, timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current),
            tzId: "Asia/Shanghai",
            tzOffset: 28_800,
            note: note,
            categoryId: SystemCategoryID.uncategorized(for: .expense),
            isFromRecurring: false,
            createdAt: date,
            updatedAt: date,
            deletedAt: nil,
            trashUntil: nil
        )
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
