import XCTest
@testable import Tally

final class CSVImportPipelineTests: XCTestCase {
    private let pipeline = CSVImportPipeline()

    func testLoadPayloadSupportsUTF8BOM() throws {
        let csv = "时间,类型,分类,金额,备注\n2026-02-01 10:00:00,支出,午餐,12.34,测试"
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(csv.utf8))

        let payload = try pipeline.loadPayload(from: data)

        XCTAssertEqual(payload.rows.count, 1)
        XCTAssertEqual(payload.rows.first?.lineNumber, 2)
        XCTAssertEqual(payload.rows.first?.columns[0], "2026-02-01 10:00:00")
    }

    func testLoadPayloadRejectsInvalidHeader() {
        let csv = "日期,类型,分类,金额,备注\n2026-02-01 10:00:00,支出,午餐,12.34,测试"
        let data = Data(csv.utf8)

        XCTAssertThrowsError(try pipeline.loadPayload(from: data)) { error in
            guard case CSVImportPipelineError.invalidHeader = error else {
                XCTFail("unexpected error: \(error)")
                return
            }
        }
    }

    func testValidateCountsPendingConflictAndFailure() throws {
        let categoryId = UUID()
        let categories = [
            CategoryRecord(
                id: categoryId,
                type: .expense,
                name: "午餐",
                iconKey: "fork.knife",
                colorHex: nil,
                isSystem: false,
                sortOrder: 1
            )
        ]

        let localDate = parseLocalDate("2026-02-01 10:00:00")
        let snapshot = TimePolicy.snapshot(for: localDate)
        let existingBill = BillRecord(
            id: UUID(),
            type: .expense,
            amount: Money(cents: 1234),
            occurredAtUTC: snapshot.occurredAtUTC,
            tzId: snapshot.tzId,
            tzOffset: snapshot.tzOffset,
            occurredLocalDate: snapshot.occurredLocalDate,
            note: nil,
            categoryId: categoryId,
            isFromRecurring: false,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            trashUntil: nil
        )

        let csv = """
        时间,类型,分类,金额,备注
        2026-02-02 11:00:00,支出,午餐,8.88,有效
        2026-02-01 10:00:00,支出,午餐,12.34,重复
        2026-02-03 12:00:00,abc,午餐,10.00,类型错误
        2026-02-03 12:00:00,支出,午餐,-3,金额错误
        """
        let payload = try pipeline.loadPayload(from: Data(csv.utf8))

        let result = pipeline.validate(
            payload: payload,
            categories: categories,
            existingBills: [existingBill],
            parseAmount: parseAmount
        )

        XCTAssertEqual(result.pendingCount, 1)
        XCTAssertEqual(result.conflictCount, 1)
        XCTAssertEqual(result.failedCount, 2)
        XCTAssertEqual(result.bills.count, 1)
        XCTAssertEqual(result.errorSummary.count, 2)
        XCTAssertTrue(result.errorSummary.contains(where: { $0.contains("第4行：类型非法") }))
        XCTAssertTrue(result.errorSummary.contains(where: { $0.contains("第5行：金额非法") }))
    }

    func testValidatePerformanceForTenThousandRows() throws {
        let categoryId = UUID()
        let categories = [
            CategoryRecord(
                id: categoryId,
                type: .expense,
                name: "午餐",
                iconKey: "fork.knife",
                colorHex: nil,
                isSystem: false,
                sortOrder: 1
            )
        ]

        var rows: [String] = ["时间,类型,分类,金额,备注"]
        rows.reserveCapacity(10_001)
        for index in 0..<10_000 {
            let day = String(format: "%02d", (index % 28) + 1)
            rows.append("2026-01-\(day) 10:00:00,支出,午餐,\(index + 1),n\(index)")
        }
        let payload = try pipeline.loadPayload(from: Data(rows.joined(separator: "\n").utf8))

        measure {
            _ = pipeline.validate(
                payload: payload,
                categories: categories,
                existingBills: [],
                parseAmount: parseAmount
            )
        }
    }

    @MainActor
    func testDefaultImportExportServiceCSVPreviewAndImportFlow() async throws {
        let now = parseLocalDate("2026-02-01 09:00:00")
        let categoryId = UUID()
        let categoryRepository = MockCategoryRepository(seed: [
            CategoryRecord(
                id: categoryId,
                type: .expense,
                name: "午餐",
                iconKey: "fork.knife",
                colorHex: nil,
                isSystem: false,
                sortOrder: 1
            )
        ])
        let billRepository = MockBillRepository()
        let originalSnapshot = WidgetDataStore.loadSnapshot()
        WidgetDataStore.saveSnapshot(.placeholder)
        defer { WidgetDataStore.saveSnapshot(originalSnapshot) }
        let service = DefaultImportExportService(
            billRepository: billRepository,
            categoryRepository: categoryRepository,
            recurringRepository: NoopRecurringRepository(),
            nowProvider: { now }
        )

        let csv = """
        时间,类型,分类,金额,备注
        2026-02-01 08:00:00,支出,午餐,10.00,早餐
        2026-02-01 08:30:00,支出,午餐,-3.00,错误金额
        """
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("tally-import-\(UUID().uuidString).csv")
        try Data(csv.utf8).write(to: fileURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let preview = try await service.previewImportCSV(from: fileURL)
        XCTAssertEqual(preview.pendingCount, 1)
        XCTAssertEqual(preview.conflictCount, 0)
        XCTAssertEqual(preview.failedCount, 1)

        let result = try await service.importCSV(from: fileURL)
        XCTAssertEqual(result.importedCount, 1)
        XCTAssertEqual(result.skippedCount, 0)
        XCTAssertEqual(result.failedCount, 1)
        XCTAssertEqual(try billRepository.list().count, 1)
        let snapshot = WidgetDataStore.loadSnapshot()
        XCTAssertEqual(snapshot.quickEntry.todayExpenseCents, 1_000)
        XCTAssertEqual(snapshot.summary.monthExpenseCents, 1_000)
    }

    @MainActor
    func testPreviewImportBackupCountsDuplicateBillIDAsConflict() async throws {
        let service = DefaultImportExportService(
            billRepository: MockBillRepository(),
            categoryRepository: MockCategoryRepository(),
            recurringRepository: NoopRecurringRepository()
        )

        let billID = UUID()
        let payload = """
        {
          "schemaVersion": 1,
          "exportedAt": "2026-02-13T00:00:00Z",
          "appVersion": "1.0(1)",
          "timezone": "Asia/Shanghai",
          "bills": [
            {
              "id": "\(billID.uuidString)",
              "type": "expense",
              "amount": "10.00",
              "occurredAtUTC": "2026-02-01T08:00:00Z",
              "occurredLocalDate": "2026-02-01",
              "tzId": "Asia/Shanghai",
              "tzOffset": 28800,
              "note": null,
              "categoryId": null,
              "isFromRecurring": false,
              "createdAt": "2026-02-01T08:00:00Z",
              "updatedAt": "2026-02-01T08:00:00Z",
              "deletedAt": null,
              "trashUntil": null
            },
            {
              "id": "\(billID.uuidString)",
              "type": "expense",
              "amount": "20.00",
              "occurredAtUTC": "2026-02-02T08:00:00Z",
              "occurredLocalDate": "2026-02-02",
              "tzId": "Asia/Shanghai",
              "tzOffset": 28800,
              "note": null,
              "categoryId": null,
              "isFromRecurring": false,
              "createdAt": "2026-02-02T08:00:00Z",
              "updatedAt": "2026-02-02T08:00:00Z",
              "deletedAt": null,
              "trashUntil": null
            }
          ],
          "categories": [],
          "recurringTasks": []
        }
        """
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("tally-backup-\(UUID().uuidString).json")
        try Data(payload.utf8).write(to: fileURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let preview = try await service.previewImportBackup(from: fileURL)
        XCTAssertEqual(preview.pendingCount, 1)
        XCTAssertEqual(preview.conflictCount, 1)
        XCTAssertEqual(preview.failedCount, 0)
    }

    @MainActor
    func testImportBackupRequiresImportWriteRepository() async throws {
        let service = DefaultImportExportService(
            billRepository: MockBillRepository(),
            categoryRepository: MockCategoryRepository(),
            recurringRepository: NoopRecurringRepository()
        )

        let payload = """
        {
          "schemaVersion": 1,
          "exportedAt": "2026-02-13T00:00:00Z",
          "appVersion": "1.0(1)",
          "timezone": "Asia/Shanghai",
          "bills": [],
          "categories": [],
          "recurringTasks": []
        }
        """
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("tally-backup-import-\(UUID().uuidString).json")
        try Data(payload.utf8).write(to: fileURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        do {
            _ = try await service.importBackup(from: fileURL)
            XCTFail("expected importBackup to fail without import write repository")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("导入环境不可用"))
        }
    }
}

private extension CSVImportPipelineTests {
    func parseLocalDate(_ text: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: text) ?? Date(timeIntervalSince1970: 0)
    }

    var parseAmount: (String) -> Int? {
        { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            guard let decimal = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")),
                  decimal > 0 else {
                return nil
            }

            let parts = trimmed.split(separator: ".", omittingEmptySubsequences: false)
            if parts.count > 2 {
                return nil
            }
            if parts.count == 2, parts[1].count > 2 {
                return nil
            }

            let cents = NSDecimalNumber(decimal: decimal * 100).intValue
            return cents > 0 ? cents : nil
        }
    }
}
