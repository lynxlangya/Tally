import CoreData
import XCTest
@testable import Tally

final class CoreDataRepositoryCorruptRowTests: XCTestCase {
    @MainActor
    func testBillListSkipsCorruptRowsAndReturnsValidRows() throws {
        let persistence = PersistenceController(inMemory: true, runsStartupSeed: false)
        let context = persistence.container.viewContext
        let repository = CoreDataBillRepository(context: context)
        let firstID = UUID()
        let secondID = UUID()

        insertBill(id: firstID, amountCents: 1_200, dayKey: "2026-04-12", in: context)
        insertBill(id: UUID(), amountCents: -1, dayKey: "2026-04-13", in: context)
        insertBill(id: secondID, amountCents: 3_400, dayKey: "2026-04-14", in: context)
        try context.save()

        let records = try repository.list()

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(Set(records.map(\.id)), [firstID, secondID])
    }

    private func insertBill(
        id: UUID,
        amountCents: Int64,
        dayKey: String,
        in context: NSManagedObjectContext
    ) {
        let now = fixedDate()
        let object = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: context)
        object.setValue(id, forKey: "id")
        object.setValue(BillType.expense.rawValue, forKey: "type")
        object.setValue(amountCents, forKey: "amount")
        object.setValue(now, forKey: "occurredAtUTC")
        object.setValue("Asia/Shanghai", forKey: "tzId")
        object.setValue(Int32(28_800), forKey: "tzOffset")
        object.setValue(dayKey, forKey: "occurredLocalDate")
        object.setValue(nil, forKey: "note")
        object.setValue(false, forKey: "isFromRecurring")
        object.setValue(now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")
    }

    private func fixedDate() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 4,
            day: 12,
            hour: 10,
            minute: 0,
            second: 0
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}
