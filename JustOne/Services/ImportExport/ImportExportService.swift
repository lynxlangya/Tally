import Foundation

protocol ImportExportService {
    func exportCSV(request: ExportRequest) async throws -> ExportResult
    func exportBackup(request: ExportRequest) async throws -> ExportResult
    func previewImportBackup(from fileURL: URL) async throws -> ImportPreview
    func previewImportCSV(from fileURL: URL) async throws -> ImportPreview
    func importBackup(from fileURL: URL) async throws -> ImportResult
    func importCSV(from fileURL: URL) async throws -> ImportResult
}

struct StubImportExportService: ImportExportService {
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
        throw ServiceError.notImplemented
    }

    func importBackup(from fileURL: URL) async throws -> ImportResult {
        throw ServiceError.notImplemented
    }

    func importCSV(from fileURL: URL) async throws -> ImportResult {
        throw ServiceError.notImplemented
    }
}
