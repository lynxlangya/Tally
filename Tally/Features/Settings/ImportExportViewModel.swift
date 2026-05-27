import Foundation
import Combine
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ImportExportViewModel: ObservableObject {
    @Published var toastMessage: String?
    @Published var selectedScope: ExportScope = .currentMonth
    @Published var isProcessing: Bool = false
    @Published var exportPayload: ExportPayload?
    @Published var backupImportPreview: BackupImportPreview?
    @Published var csvImportPreview: CSVImportPreview?
    @Published var importResultDialog: ImportResultDialog?
    @Published private var currentBills: [BillRecord] = []
    @Published private(set) var logs: [ImportExportLog] = []

    private let service: ImportExportService
    private let billRepository: BillRepository
    private let logDefaults: UserDefaults
    private let nowProvider: () -> Date
    private var dismissToastTask: Task<Void, Never>?

    init(
        service: ImportExportService,
        billRepository: BillRepository,
        logDefaults: UserDefaults = .standard,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.service = service
        self.billRepository = billRepository
        self.logDefaults = logDefaults
        self.nowProvider = nowProvider
        self.logs = ImportExportLogStore.load(defaults: logDefaults)
        reloadCurrentData()
    }

    deinit {
        dismissToastTask?.cancel()
    }

    var currentRecordCount: Int {
        currentBills.count
    }

    var dateRange: (Date, Date)? {
        dayKeyRange
    }

    var dateRangeSubtitle: String {
        guard let dayKeyRange else { return "暂无记录跨度" }
        let dayCount = max(
            1,
            (Self.dayKeyCalendar.dateComponents([.day], from: dayKeyRange.0, to: dayKeyRange.1).day ?? 0) + 1
        )
        return "跨度 \(Self.rangeDateFormatter.string(from: dayKeyRange.0)) — \(Self.rangeDateFormatter.string(from: dayKeyRange.1)) · \(dayCount) 天"
    }

    private var dayKeyRange: (Date, Date)? {
        let dayKeys = currentBills.map(\.occurredLocalDate)
        guard
            let minKey = dayKeys.min(),
            let maxKey = dayKeys.max(),
            let start = DayKeyFormatter.date(from: minKey, timeZone: Self.dayKeyCalendar.timeZone),
            let end = DayKeyFormatter.date(from: maxKey, timeZone: Self.dayKeyCalendar.timeZone)
        else {
            return nil
        }
        return (start, end)
    }

    func reloadCurrentData() {
        do {
            currentBills = try billRepository.list().filter { $0.deletedAt == nil }
        } catch {
            currentBills = []
            showToast(error.localizedDescription)
        }
    }

    func exportCSV() {
        runExportAction(title: "导出 CSV", kind: .csv) { [service, selectedScope] in
            try await service.exportCSV(request: ExportRequest(scope: selectedScope, type: .csv))
        }
    }

    func exportBackup() {
        runExportAction(title: "导出备份 JSON", kind: .backupJSON) { [service, selectedScope] in
            try await service.exportBackup(request: ExportRequest(scope: selectedScope, type: .backupJSON))
        }
    }

    func prepareImportBackup(fileURL: URL) {
        prepareImport(fileURL: fileURL, kind: .backup)
    }

    func confirmImportBackup() {
        confirmImport(kind: .backup)
    }

    func dismissImportBackupPreview() {
        backupImportPreview = nil
    }

    func prepareImportCSV(fileURL: URL) {
        prepareImport(fileURL: fileURL, kind: .csv)
    }

    func confirmImportCSV() {
        confirmImport(kind: .csv)
    }

    func dismissImportCSVPreview() {
        csvImportPreview = nil
    }

    func dismissImportResultDialog() {
        importResultDialog = nil
    }

    func clearExportPayload() {
        exportPayload = nil
    }

    var backupImportPreviewMessage: String {
        guard let preview = backupImportPreview?.preview else { return "" }
        return previewMessage(preview)
    }

    var csvImportPreviewMessage: String {
        guard let preview = csvImportPreview?.preview else { return "" }
        return previewMessage(preview)
    }

    private func prepareImport(fileURL: URL, kind: ImportKind) {
        guard !isProcessing else { return }
        isProcessing = true

        Task { [weak self] in
            guard let self else { return }
            defer { isProcessing = false }

            do {
                let preview = try await fetchPreview(fileURL: fileURL, kind: kind)
                setImportPreview(fileURL: fileURL, preview: preview, for: kind)
            } catch ServiceError.notImplemented {
                recordLog(status: .failure, title: kind.title, count: 0, errors: 1)
                showToast(kind.notImplementedToast)
            } catch {
                recordLog(status: .failure, title: kind.title, count: 0, errors: 1)
                showToast(error.localizedDescription)
            }
        }
    }

    private func confirmImport(kind: ImportKind) {
        guard let fileURL = clearImportPreviewAndGetFileURL(for: kind) else { return }
        guard !isProcessing else { return }
        isProcessing = true

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        Task { [weak self] in
            guard let self else { return }
            defer { isProcessing = false }

            do {
                let result = try await runImport(fileURL: fileURL, kind: kind)
                NotificationCenter.default.post(name: .billDidChange, object: nil)
                reloadCurrentData()
                recordLog(
                    status: result.failedCount > 0 ? .warning : .success,
                    title: kind.title,
                    count: result.importedCount,
                    errors: result.failedCount
                )
                importResultDialog = ImportResultDialog(
                    title: "导入结果",
                    importedCount: result.importedCount,
                    skippedCount: result.skippedCount,
                    failedCount: result.failedCount
                )
            } catch ServiceError.notImplemented {
                recordLog(status: .failure, title: kind.title, count: 0, errors: 1)
                showToast(kind.notImplementedToast)
            } catch {
                recordLog(status: .failure, title: kind.title, count: 0, errors: 1)
                showToast(error.localizedDescription)
            }
        }
    }

    private func fetchPreview(fileURL: URL, kind: ImportKind) async throws -> ImportPreview {
        switch kind {
        case .backup:
            return try await service.previewImportBackup(from: fileURL)
        case .csv:
            return try await service.previewImportCSV(from: fileURL)
        }
    }

    private func runImport(fileURL: URL, kind: ImportKind) async throws -> ImportResult {
        switch kind {
        case .backup:
            return try await service.importBackup(from: fileURL)
        case .csv:
            return try await service.importCSV(from: fileURL)
        }
    }

    private func setImportPreview(fileURL: URL, preview: ImportPreview, for kind: ImportKind) {
        switch kind {
        case .backup:
            backupImportPreview = BackupImportPreview(fileURL: fileURL, preview: preview)
        case .csv:
            csvImportPreview = CSVImportPreview(fileURL: fileURL, preview: preview)
        }
    }

    private func clearImportPreviewAndGetFileURL(for kind: ImportKind) -> URL? {
        switch kind {
        case .backup:
            defer { backupImportPreview = nil }
            return backupImportPreview?.fileURL
        case .csv:
            defer { csvImportPreview = nil }
            return csvImportPreview?.fileURL
        }
    }

    private func previewMessage(_ preview: ImportPreview) -> String {
        var lines: [String] = [
            "可导入：\(preview.pendingCount)",
            "冲突：\(preview.conflictCount)",
            "失败：\(preview.failedCount)"
        ]

        if !preview.errorSummary.isEmpty {
            lines.append("错误摘要：")
            lines.append(contentsOf: preview.errorSummary.map { "• \($0)" })
        }

        return lines.joined(separator: "\n")
    }

    private func runExportAction(
        title: String,
        kind: ExportFileKind,
        operation: @escaping () async throws -> ExportResult
    ) {
        guard !isProcessing else { return }
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        isProcessing = true

        Task { [weak self] in
            guard let self else { return }
            defer { isProcessing = false }

            do {
                let result = try await operation()
                let data = try Data(contentsOf: result.fileURL)
                exportPayload = ExportPayload(
                    data: data,
                    contentType: kind.contentType,
                    defaultFilename: result.fileURL.lastPathComponent
                )
                recordLog(status: .success, title: title, count: result.recordCount, errors: 0)
                if let size = result.fileSizeBytes {
                    showToast("已生成\(title)（\(result.recordCount)条，\(formatFileSize(size))）")
                } else {
                    showToast("已生成\(title)（\(result.recordCount)条）")
                }
            } catch ServiceError.notImplemented {
                recordLog(status: .failure, title: title, count: 0, errors: 1)
                showToast("\(title)功能开发中")
            } catch {
                recordLog(status: .failure, title: title, count: 0, errors: 1)
                showToast("\(title)失败，请稍后重试")
            }
        }
    }

    private func recordLog(status: ImportExportLog.Status, title: String, count: Int, errors: Int) {
        let log = ImportExportLog(
            status: status,
            title: title,
            createdAt: nowProvider(),
            count: count,
            errors: errors
        )
        logs = ImportExportLogStore.prepend(log, to: logs)
        ImportExportLogStore.save(logs, defaults: logDefaults)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        dismissToastTask?.cancel()
        dismissToastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.toastMessage = nil
            }
        }
    }

    private enum ImportKind {
        case backup
        case csv

        var title: String {
            switch self {
            case .backup:
                return "导入备份"
            case .csv:
                return "导入 CSV"
            }
        }

        var notImplementedToast: String {
            switch self {
            case .backup:
                return "导入备份功能开发中"
            case .csv:
                return "导入 CSV 功能开发中"
            }
        }
    }

    private enum ExportFileKind {
        case csv
        case backupJSON

        var contentType: UTType {
            switch self {
            case .csv:
                return .commaSeparatedText
            case .backupJSON:
                return .json
            }
        }
    }

    private static let dayKeyCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    private static let rangeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = dayKeyCalendar
        formatter.timeZone = dayKeyCalendar.timeZone
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()
}

extension ImportExportViewModel {
    struct ExportPayload: Identifiable {
        let id = UUID()
        let data: Data
        let contentType: UTType
        let defaultFilename: String
    }

    struct BackupImportPreview: Identifiable {
        let id = UUID()
        let fileURL: URL
        let preview: ImportPreview
    }

    struct CSVImportPreview: Identifiable {
        let id = UUID()
        let fileURL: URL
        let preview: ImportPreview
    }

    struct ImportResultDialog: Identifiable {
        let id = UUID()
        let title: String
        let importedCount: Int
        let skippedCount: Int
        let failedCount: Int

        var message: String {
            [
                "成功：\(importedCount)",
                "跳过：\(skippedCount)",
                "失败：\(failedCount)"
            ].joined(separator: "\n")
        }
    }
}
