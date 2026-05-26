import Foundation

protocol ExportService {
    func exportCSV(range: DateInterval) throws -> URL
    func exportPDF(range: DateInterval) throws -> URL
}

struct StubExportService: ExportService {
    func exportCSV(range: DateInterval) throws -> URL {
        throw ServiceError.notImplemented
    }

    func exportPDF(range: DateInterval) throws -> URL {
        throw ServiceError.notImplemented
    }
}
