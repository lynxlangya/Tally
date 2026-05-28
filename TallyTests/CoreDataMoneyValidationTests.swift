import CoreData
import XCTest
@testable import Tally

final class CoreDataMoneyValidationTests: XCTestCase {
    @MainActor
    func testBillRepositoryThrowsInvalidDataForNegativeStoredAmount() throws {
        let persistence = PersistenceController(inMemory: true, runsStartupSeed: false)
        let context = persistence.container.viewContext
        try insertBill(amount: -1, in: context)

        let repository = CoreDataBillRepository(context: context)

        assertInvalidData(field: "Bill.amount") {
            _ = try repository.list()
        }
    }

    @MainActor
    func testRecurringRepositoryThrowsInvalidDataForNegativeStoredAmount() throws {
        let persistence = PersistenceController(inMemory: true, runsStartupSeed: false)
        let context = persistence.container.viewContext
        try insertRecurringTask(amount: -1, in: context)

        let repository = CoreDataRecurringRepository(context: context)

        assertInvalidData(field: "RecurringTask.amount") {
            _ = try repository.list()
        }
    }

    private func insertBill(amount: Int64, in context: NSManagedObjectContext) throws {
        let now = fixedDate()
        let snapshot = TimePolicy.snapshot(for: now)
        let object = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: context)
        object.setValue(UUID(), forKey: "id")
        object.setValue(BillType.expense.rawValue, forKey: "type")
        object.setValue(amount, forKey: "amount")
        object.setValue(snapshot.occurredAtUTC, forKey: "occurredAtUTC")
        object.setValue(snapshot.tzId, forKey: "tzId")
        object.setValue(Int32(snapshot.tzOffset), forKey: "tzOffset")
        object.setValue(snapshot.occurredLocalDate, forKey: "occurredLocalDate")
        object.setValue(nil, forKey: "note")
        object.setValue(nil, forKey: "categoryId")
        object.setValue(false, forKey: "isFromRecurring")
        object.setValue(now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")
        object.setValue(nil, forKey: "deletedAt")
        object.setValue(nil, forKey: "trashUntil")
        try context.save()
    }

    private func insertRecurringTask(amount: Int64, in context: NSManagedObjectContext) throws {
        let now = fixedDate()
        let object = NSEntityDescription.insertNewObject(forEntityName: "RecurringTask", into: context)
        object.setValue(UUID(), forKey: "id")
        object.setValue(BillType.expense.rawValue, forKey: "type")
        object.setValue(amount, forKey: "amount")
        object.setValue(nil, forKey: "categoryId")
        object.setValue(nil, forKey: "note")
        object.setValue(now, forKey: "firstDate")
        object.setValue(RepeatRule.daily.rawValue, forKey: "repeatRule")
        object.setValue(now, forKey: "nextFireDate")
        object.setValue(Int16(9), forKey: "hour")
        object.setValue(Int16(0), forKey: "minute")
        object.setValue(nil, forKey: "lastRunAtUTC")
        object.setValue(true, forKey: "isEnabled")
        object.setValue(now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")
        try context.save()
    }

    private func fixedDate() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return calendar.date(
            from: DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                year: 2026,
                month: 5,
                day: 28,
                hour: 9,
                minute: 30
            )
        ) ?? Date(timeIntervalSince1970: 0)
    }

    private func assertInvalidData(
        field: String,
        _ expression: () throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard case RepositoryError.invalidData(let actualField) = error else {
                XCTFail("Expected RepositoryError.invalidData, got \(error)", file: file, line: line)
                return
            }
            XCTAssertEqual(actualField, field, file: file, line: line)
        }
    }
}
