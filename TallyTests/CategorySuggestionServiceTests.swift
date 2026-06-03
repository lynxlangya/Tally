import XCTest
@testable import Tally

final class CategorySuggestionServiceTests: XCTestCase {
    private let shanghaiTimeZone = TimeZone(identifier: "Asia/Shanghai")!
    private var savedDefaultTimeZone: TimeZone!

    override func setUp() {
        super.setUp()
        savedDefaultTimeZone = TimeZone.current
        NSTimeZone.default = shanghaiTimeZone
    }

    override func tearDown() {
        NSTimeZone.default = savedDefaultTimeZone
        super.tearDown()
    }

    func testPureScoringPrioritizesCurrentTimeSlice() {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 12, minute: 0)
        let lunch = makeCategory(id: uuid("00000000-0000-0000-0000-000000000101"), name: "午餐", sortOrder: 3)
        let coffee = makeCategory(id: uuid("00000000-0000-0000-0000-000000000102"), name: "咖啡", sortOrder: 0)
        let records = (0..<6).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 10), categoryId: lunch.id)
        } + (0..<6).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 18, minute: 0), categoryId: coffee.id)
        }

        let ordered = DefaultCategorySuggestionService.orderedCategoryIDs(
            from: records,
            type: .expense,
            now: now,
            candidates: [coffee, lunch]
        )

        XCTAssertEqual(ordered.prefix(2), [lunch.id, coffee.id])
    }

    func testPureScoringPrioritizesRecencyWhenFrequencyAndTimeTie() {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 12, minute: 0)
        let recent = makeCategory(id: uuid("00000000-0000-0000-0000-000000000201"), name: "最近", sortOrder: 5)
        let old = makeCategory(id: uuid("00000000-0000-0000-0000-000000000202"), name: "较早", sortOrder: 0)
        let recentRecords = (0..<5).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 8, minute: 0), categoryId: recent.id)
        }
        let oldRecords = (0..<5).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 4, day: 6 - offset, hour: 8, minute: 0), categoryId: old.id)
        }

        let ordered = DefaultCategorySuggestionService.orderedCategoryIDs(
            from: recentRecords + oldRecords,
            type: .expense,
            now: now,
            candidates: [old, recent]
        )

        XCTAssertEqual(ordered.first, recent.id)
    }

    func testPureScoringWrapsTimeWindowAcrossMidnight() {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 23, minute: 0)
        let midnight = makeCategory(id: uuid("00000000-0000-0000-0000-000000000301"), name: "夜宵", sortOrder: 4)
        let evening = makeCategory(id: uuid("00000000-0000-0000-0000-000000000302"), name: "晚间", sortOrder: 0)
        let records = (0..<5).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 0, minute: 30), categoryId: midnight.id)
        } + (0..<5).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 22, minute: 30), categoryId: midnight.id)
        } + (0..<10).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 20, minute: 0), categoryId: evening.id)
        }

        let ordered = DefaultCategorySuggestionService.orderedCategoryIDs(
            from: records,
            type: .expense,
            now: now,
            candidates: [evening, midnight]
        )

        XCTAssertEqual(ordered.first, midnight.id)
    }

    func testPureScoringDoesNotCountDistantHourWhenWindowWrapsMidnight() {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 23, minute: 0)
        let near = makeCategory(id: uuid("00000000-0000-0000-0000-000000000303"), name: "夜间", sortOrder: 5)
        let distant = makeCategory(id: uuid("00000000-0000-0000-0000-000000000304"), name: "午间", sortOrder: 0)
        let records = (0..<5).flatMap { offset in
            [
                makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 23, minute: 20), categoryId: near.id),
                makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 0), categoryId: distant.id)
            ]
        }

        let ordered = DefaultCategorySuggestionService.orderedCategoryIDs(
            from: records,
            type: .expense,
            now: now,
            candidates: [distant, near]
        )

        XCTAssertEqual(ordered.prefix(2), [near.id, distant.id])
    }

    func testPureScoringFallsBackToSortOrderWhenHistoryIsInsufficient() {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 12, minute: 0)
        let first = makeCategory(id: uuid("00000000-0000-0000-0000-000000000401"), name: "第一", sortOrder: 0)
        let second = makeCategory(id: uuid("00000000-0000-0000-0000-000000000402"), name: "第二", sortOrder: 1)
        let third = makeCategory(id: uuid("00000000-0000-0000-0000-000000000403"), name: "第三", sortOrder: 2)
        let records = (0..<9).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 0), categoryId: third.id)
        }

        let ordered = DefaultCategorySuggestionService.orderedCategoryIDs(
            from: records,
            type: .expense,
            now: now,
            candidates: [third, first, second]
        )

        XCTAssertEqual(ordered, [first.id, second.id, third.id])
    }

    func testPureScoringFallsBackToSortOrderWhenScoresTie() {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 12, minute: 0)
        let first = makeCategory(id: uuid("00000000-0000-0000-0000-000000000501"), name: "低序", sortOrder: 0)
        let second = makeCategory(id: uuid("00000000-0000-0000-0000-000000000502"), name: "高序", sortOrder: 5)
        let records = (0..<5).flatMap { offset in
            [
                makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 8, minute: 0), categoryId: first.id),
                makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 8, minute: 0), categoryId: second.id)
            ]
        }

        let ordered = DefaultCategorySuggestionService.orderedCategoryIDs(
            from: records,
            type: .expense,
            now: now,
            candidates: [second, first]
        )

        XCTAssertEqual(ordered.prefix(2), [first.id, second.id])
    }

    func testDefaultServiceFiltersHistoryAndUsesRepositoryRange() {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 12, minute: 0)
        let food = makeCategory(id: uuid("00000000-0000-0000-0000-000000000601"), name: "午餐", sortOrder: 5)
        let coffee = makeCategory(id: uuid("00000000-0000-0000-0000-000000000602"), name: "咖啡", sortOrder: 0)
        let removedID = uuid("00000000-0000-0000-0000-000000000603")
        let validRecords = (0..<10).map { offset in
            makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 0), categoryId: food.id)
        }
        let ignoredRecords = (0..<20).flatMap { offset in
            [
                makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 0), categoryId: coffee.id, isFromRecurring: true),
                makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 0), categoryId: nil),
                makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 0), categoryId: SystemCategoryID.uncategorized(for: .expense)),
                makeBill(date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 0), categoryId: removedID),
                makeBill(type: .income, date: fixedDate(year: 2026, month: 5, day: 26 - offset, hour: 12, minute: 0), categoryId: coffee.id)
            ]
        } + [
            makeBill(date: fixedDate(year: 2026, month: 2, day: 1, hour: 12, minute: 0), categoryId: coffee.id)
        ]
        let repository = InMemoryBillRepository(records: validRecords + ignoredRecords)
        let service = DefaultCategorySuggestionService(billRepository: repository)

        let ordered = service.orderedCategoryIDs(
            type: .expense,
            now: now,
            candidates: [coffee, food]
        )

        XCTAssertEqual(ordered.prefix(2), [food.id, coffee.id])
    }

    func testDefaultServiceFallsBackToInputOrderWhenRepositoryThrows() {
        let now = fixedDate(year: 2026, month: 5, day: 26, hour: 12, minute: 0)
        let first = makeCategory(id: uuid("00000000-0000-0000-0000-000000000701"), name: "第一", sortOrder: 0)
        let second = makeCategory(id: uuid("00000000-0000-0000-0000-000000000702"), name: "第二", sortOrder: 1)
        let repository = InMemoryBillRepository()
        repository.listError = RepositoryError.invalidData(field: "list")
        let service = DefaultCategorySuggestionService(billRepository: repository)

        let ordered = service.orderedCategoryIDs(
            type: .expense,
            now: now,
            candidates: [second, first]
        )

        XCTAssertEqual(ordered, [second.id, first.id])
    }

    private func makeCategory(
        id: UUID,
        type: BillType = .expense,
        name: String,
        sortOrder: Int
    ) -> CategoryRecord {
        CategoryRecord(
            id: id,
            type: type,
            name: name,
            iconKey: "fork.knife",
            colorHex: nil,
            isSystem: false,
            sortOrder: sortOrder
        )
    }

    private func makeBill(
        type: BillType = .expense,
        date: Date,
        categoryId: UUID?,
        isFromRecurring: Bool = false
    ) -> BillRecord {
        let snapshot = TimePolicy.snapshot(for: date, timeZone: shanghaiTimeZone)
        return BillRecord(
            id: UUID(),
            type: type,
            amount: Money(cents: 1_000),
            occurredAtUTC: snapshot.occurredAtUTC,
            tzId: snapshot.tzId,
            tzOffset: snapshot.tzOffset,
            occurredLocalDate: snapshot.occurredLocalDate,
            note: nil,
            categoryId: categoryId,
            isFromRecurring: isFromRecurring,
            createdAt: date,
            updatedAt: date,
            deletedAt: nil,
            trashUntil: nil
        )
    }

    private func fixedDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = shanghaiTimeZone
        let components = DateComponents(
            calendar: calendar,
            timeZone: shanghaiTimeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: 0
        )
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    private func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}
