import XCTest
@testable import JustOne

final class ImportExportViewModelTests: XCTestCase {
    @MainActor
    func testConfirmImportCSVPostsBillDidChangeOnSuccess() async throws {
        let service = SpyImportExportService(
            csvPreview: ImportPreview(pendingCount: 1, conflictCount: 0, failedCount: 0, errorSummary: []),
            csvImportOutcome: .success(ImportResult(importedCount: 1, skippedCount: 0, failedCount: 0))
        )
        let viewModel = ImportExportViewModel(service: service)
        let fileURL = URL(fileURLWithPath: "/tmp/justone-import-success.csv")
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
    }

    @MainActor
    func testConfirmImportCSVDoesNotPostBillDidChangeOnFailure() async throws {
        let service = SpyImportExportService(
            csvPreview: ImportPreview(pendingCount: 1, conflictCount: 0, failedCount: 0, errorSummary: []),
            csvImportOutcome: .failure(MockImportError())
        )
        let viewModel = ImportExportViewModel(service: service)
        let fileURL = URL(fileURLWithPath: "/tmp/justone-import-failure.csv")
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
}

private final class SpyImportExportService: ImportExportService {
    private let csvPreview: ImportPreview
    private let csvImportOutcome: Result<ImportResult, Error>

    private(set) var importCSVCallCount = 0

    init(
        csvPreview: ImportPreview,
        csvImportOutcome: Result<ImportResult, Error>
    ) {
        self.csvPreview = csvPreview
        self.csvImportOutcome = csvImportOutcome
    }

    func exportCSV(request: ExportRequest) async throws -> ExportResult {
        throw ServiceError.notImplemented
    }

    func exportBackup(request: ExportRequest) async throws -> ExportResult {
        throw ServiceError.notImplemented
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
