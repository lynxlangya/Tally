import Foundation

extension BillsListViewModel {
    static let mockAnchorDate: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let components = DateComponents(calendar: calendar, year: 2026, month: 1, day: 17, hour: 12, minute: 0)
        return calendar.date(from: components) ?? Date()
    }()

    static func makeMockData(anchor: Date) -> (bills: [BillRecord], categories: [CategoryRecord]) {
        let rentId = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let foodId = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        let transitId = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!
        let shoppingId = UUID(uuidString: "00000000-0000-0000-0000-000000000104")!
        let funId = UUID(uuidString: "00000000-0000-0000-0000-000000000105")!
        let salaryId = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!
        let bonusId = UUID(uuidString: "00000000-0000-0000-0000-000000000202")!
        let investId = UUID(uuidString: "00000000-0000-0000-0000-000000000203")!

        let categories: [CategoryRecord] = [
            CategoryRecord(id: rentId, type: .expense, name: "房租", iconKey: "house.fill", colorHex: 0x13EC37, isSystem: false, sortOrder: 1),
            CategoryRecord(id: foodId, type: .expense, name: "餐饮", iconKey: "fork.knife", colorHex: 0xF97316, isSystem: false, sortOrder: 2),
            CategoryRecord(id: transitId, type: .expense, name: "交通", iconKey: "train.side.front.car", colorHex: 0x38BDF8, isSystem: false, sortOrder: 3),
            CategoryRecord(id: shoppingId, type: .expense, name: "购物", iconKey: "cart.fill", colorHex: 0xA855F7, isSystem: false, sortOrder: 4),
            CategoryRecord(id: funId, type: .expense, name: "娱乐", iconKey: "gamecontroller.fill", colorHex: 0xF472B6, isSystem: false, sortOrder: 5),
            CategoryRecord(id: salaryId, type: .income, name: "工资", iconKey: "creditcard.fill", colorHex: 0x22C55E, isSystem: false, sortOrder: 1),
            CategoryRecord(id: bonusId, type: .income, name: "奖金", iconKey: "gift.fill", colorHex: 0x3B82F6, isSystem: false, sortOrder: 2),
            CategoryRecord(id: investId, type: .income, name: "理财", iconKey: "chart.line.uptrend.xyaxis", colorHex: 0x14B8A6, isSystem: false, sortOrder: 3)
        ]

        let bills: [BillRecord] = [
            makeBill(type: .expense, cents: 320_000, date: makeDate(2026, 1, 1, 9, 0), categoryId: rentId, note: "房租"),
            makeBill(type: .expense, cents: 12_800, date: makeDate(2026, 1, 3, 8, 30), categoryId: foodId, note: "早餐"),
            makeBill(type: .expense, cents: 6_200, date: makeDate(2026, 1, 5, 9, 10), categoryId: transitId, note: "通勤"),
            makeBill(type: .expense, cents: 38_600, date: makeDate(2026, 1, 7, 14, 20), categoryId: shoppingId, note: "衣物"),
            makeBill(type: .expense, cents: 26_800, date: makeDate(2026, 1, 10, 19, 10), categoryId: foodId, note: "聚餐"),
            makeBill(type: .expense, cents: 18_500, date: makeDate(2026, 1, 12, 20, 0), categoryId: funId, note: "电影"),
            makeBill(type: .expense, cents: 8_200, date: makeDate(2026, 1, 14, 9, 20), categoryId: transitId, note: "地铁"),
            makeBill(type: .expense, cents: 42_000, date: makeDate(2026, 1, 15, 17, 30), categoryId: shoppingId, note: "数码"),
            makeBill(type: .expense, cents: 15_600, date: makeDate(2026, 1, 17, 12, 0), categoryId: foodId, note: "午餐"),
            makeBill(type: .income, cents: 800_000, date: makeDate(2026, 1, 5, 10, 0), categoryId: salaryId, note: "工资"),
            makeBill(type: .income, cents: 180_000, date: makeDate(2026, 1, 12, 10, 0), categoryId: bonusId, note: "奖金"),
            makeBill(type: .income, cents: 95_000, date: makeDate(2026, 1, 16, 10, 0), categoryId: investId, note: "理财"),
            makeBill(type: .income, cents: 30_000, date: makeDate(2026, 1, 17, 16, 0), categoryId: bonusId, note: "奖励")
        ]

        return (bills, categories)
    }

    private static func makeBill(
        type: BillType,
        cents: Int,
        date: Date,
        categoryId: UUID,
        note: String
    ) -> BillRecord {
        let snapshot = TimePolicy.snapshot(for: date)
        return BillRecord(
            id: UUID(),
            type: type,
            amount: Money(cents: cents),
            occurredAtUTC: snapshot.occurredAtUTC,
            tzId: snapshot.tzId,
            tzOffset: snapshot.tzOffset,
            occurredLocalDate: snapshot.occurredLocalDate,
            note: note,
            categoryId: categoryId,
            isFromRecurring: false,
            createdAt: date,
            updatedAt: date,
            deletedAt: nil,
            trashUntil: nil
        )
    }

    private static func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }
}
