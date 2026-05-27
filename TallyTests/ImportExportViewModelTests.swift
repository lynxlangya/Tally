import XCTest
@testable import Tally

final class ImportExportViewModelTests: XCTestCase {
    @MainActor
    func testCurrentRecordCountAndDateRangeUseBillRepository() throws {
        let defaults = makeDefaults()
        let billRepository = MockBillRepository(seed: [
            makeBill(dayKey: "2026-05-01"),
            makeBill(dayKey: "2026-05-03"),
            makeBill(dayKey: "2026-05-02", deletedAt: Date())
        ])
        let viewModel = ImportExportViewModel(
            service: SpyImportExportService(),
            billRepository: billRepository,
            logDefaults: defaults
        )

        XCTAssertEqual(viewModel.currentRecordCount, 2)
        XCTAssertEqual(viewModel.dateRangeSubtitle, "跨度 2026/5/1 — 2026/5/3 · 3 天")
    }

    @MainActor
    func testExportCSVCreatesPayloadAndPersistsSuccessLog() async throws {
        let defaults = makeDefaults()
        let exportURL = temporaryFileURL(name: "tally-export.csv", contents: "时间,类型\n")
        let service = SpyImportExportService(
            exportCSVResult: ExportResult(fileURL: exportURL, recordCount: 2, fileSizeBytes: 12)
        )
        let viewModel = ImportExportViewModel(
            service: service,
            billRepository: MockBillRepository(),
            logDefaults: defaults,
            nowProvider: { [self] in fixedDate(year: 2026, month: 5, day: 27, hour: 9, minute: 30) }
        )

        viewModel.exportCSV()
        try await waitUntil { viewModel.exportPayload != nil }

        XCTAssertEqual(service.exportCSVCallCount, 1)
        XCTAssertEqual(viewModel.exportPayload?.defaultFilename, "tally-export.csv")
        XCTAssertEqual(viewModel.exportPayload?.data, Data("时间,类型\n".utf8))
        XCTAssertEqual(viewModel.logs.first?.title, "导出 CSV")
        XCTAssertEqual(viewModel.logs.first?.status, .success)
        XCTAssertEqual(ImportExportLogStore.load(defaults: defaults).first?.count, 2)
    }

    @MainActor
    func testConfirmImportCSVPostsBillDidChangeAndPersistsLogOnSuccess() async throws {
        let defaults = makeDefaults()
        let service = SpyImportExportService(
            csvPreview: ImportPreview(pendingCount: 1, conflictCount: 0, failedCount: 0, errorSummary: []),
            csvImportOutcome: .success(ImportResult(importedCount: 1, skippedCount: 0, failedCount: 0))
        )
        let viewModel = ImportExportViewModel(
            service: service,
            billRepository: MockBillRepository(),
            logDefaults: defaults,
            nowProvider: { [self] in fixedDate(year: 2026, month: 5, day: 27, hour: 9, minute: 30) }
        )
        let fileURL = URL(fileURLWithPath: "/tmp/tally-import-success.csv")
        var notificationCount = 0
        let token = NotificationCenter.default.addObserver(
            forName: .billDidChange,
            object: nil,
            queue: nil
        ) { _ in
            notificationCount += 1
        }
        defer { NotificationCenter.default.removeObserver(token) }

        viewModel.prepareImportCSV(fileURL: fileURL)
        try await waitUntil { viewModel.csvImportPreview != nil }

        viewModel.confirmImportCSV()
        try await waitUntil { viewModel.importResultDialog != nil }

        XCTAssertEqual(notificationCount, 1)
        XCTAssertEqual(viewModel.importResultDialog?.importedCount, 1)
        XCTAssertEqual(service.importCSVCallCount, 1)
        XCTAssertEqual(viewModel.logs.first?.title, "导入 CSV")
        XCTAssertEqual(viewModel.logs.first?.status, .success)
        XCTAssertEqual(ImportExportLogStore.load(defaults: defaults).first?.count, 1)
    }

    @MainActor
    func testConfirmImportCSVDoesNotPostBillDidChangeOnFailure() async throws {
        let defaults = makeDefaults()
        let service = SpyImportExportService(
            csvPreview: ImportPreview(pendingCount: 1, conflictCount: 0, failedCount: 0, errorSummary: []),
            csvImportOutcome: .failure(MockImportError())
        )
        let viewModel = ImportExportViewModel(
            service: service,
            billRepository: MockBillRepository(),
            logDefaults: defaults
        )
        let fileURL = URL(fileURLWithPath: "/tmp/tally-import-failure.csv")
        var notificationCount = 0
        let token = NotificationCenter.default.addObserver(
            forName: .billDidChange,
            object: nil,
            queue: nil
        ) { _ in
            notificationCount += 1
        }
        defer { NotificationCenter.default.removeObserver(token) }

        viewModel.prepareImportCSV(fileURL: fileURL)
        try await waitUntil { viewModel.csvImportPreview != nil }

        viewModel.confirmImportCSV()
        try await waitUntil { viewModel.isProcessing == false }

        XCTAssertEqual(notificationCount, 0)
        XCTAssertNil(viewModel.importResultDialog)
        XCTAssertEqual(viewModel.toastMessage, "mock import failed")
        XCTAssertEqual(viewModel.logs.first?.status, .failure)
        XCTAssertEqual(viewModel.logs.first?.errors, 1)
    }

    func testImportExportLogStoreCapsAtTwentyEntries() {
        let logs = (0..<25).map { index in
            ImportExportLog(status: .success, title: "log \(index)", count: index, errors: 0)
        }

        let capped = ImportExportLogStore.prepend(
            ImportExportLog(status: .failure, title: "new", count: 0, errors: 1),
            to: logs
        )

        XCTAssertEqual(capped.count, 20)
        XCTAssertEqual(capped.first?.title, "new")
        XCTAssertEqual(capped.last?.title, "log 18")
    }
}

private extension ImportExportViewModelTests {
    @MainActor
    func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while !condition() {
            if DispatchTime.now().uptimeNanoseconds > deadline {
                XCTFail("waitUntil timed out")
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    func makeDefaults() -> UserDefaults {
        let suiteName = "ImportExportViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removeObject(forKey: ImportExportLogStore.key)
        return defaults
    }

    func temporaryFileURL(name: String, contents: String) -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try? Data(contents.utf8).write(to: url, options: .atomic)
        return url
    }

    func makeBill(dayKey: String, deletedAt: Date? = nil) -> BillRecord {
        let date = DayKeyFormatter.date(from: dayKey, timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current) ?? Date()
        return BillRecord(
            id: UUID(),
            type: .expense,
            amount: Money(cents: 1000),
            occurredAtUTC: date,
            tzId: "Asia/Shanghai",
            tzOffset: 28_800,
            occurredLocalDate: dayKey,
            note: nil,
            categoryId: UUID(),
            isFromRecurring: false,
            createdAt: date,
            updatedAt: date,
            deletedAt: deletedAt,
            trashUntil: nil
        )
    }

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

private final class SpyImportExportService: ImportExportService {
    private let exportCSVResult: ExportResult
    private let exportBackupResult: ExportResult
    private let csvPreview: ImportPreview
    private let csvImportOutcome: Result<ImportResult, Error>

    private(set) var exportCSVCallCount = 0
    private(set) var importCSVCallCount = 0

    init(
        exportCSVResult: ExportResult = ExportResult(fileURL: URL(fileURLWithPath: "/tmp/tally-export.csv"), recordCount: 0, fileSizeBytes: nil),
        exportBackupResult: ExportResult = ExportResult(fileURL: URL(fileURLWithPath: "/tmp/tally-backup.json"), recordCount: 0, fileSizeBytes: nil),
        csvPreview: ImportPreview = ImportPreview(pendingCount: 0, conflictCount: 0, failedCount: 0, errorSummary: []),
        csvImportOutcome: Result<ImportResult, Error> = .success(ImportResult(importedCount: 0, skippedCount: 0, failedCount: 0))
    ) {
        self.exportCSVResult = exportCSVResult
        self.exportBackupResult = exportBackupResult
        self.csvPreview = csvPreview
        self.csvImportOutcome = csvImportOutcome
    }

    func exportCSV(request: ExportRequest) async throws -> ExportResult {
        exportCSVCallCount += 1
        return exportCSVResult
    }

    func exportBackup(request: ExportRequest) async throws -> ExportResult {
        exportBackupResult
    }

    func previewImportBackup(from fileURL: URL) async throws -> ImportPreview {
        throw ServiceError.notImplemented
    }

    func previewImportCSV(from fileURL: URL) async throws -> ImportPreview {
        csvPreview
    }

    func importBackup(from fileURL: URL) async throws -> ImportResult {
        throw ServiceError.notImplemented
    }

    func importCSV(from fileURL: URL) async throws -> ImportResult {
        importCSVCallCount += 1
        return try csvImportOutcome.get()
    }
}

private struct MockImportError: LocalizedError {
    var errorDescription: String? { "mock import failed" }
}
