import Foundation
import Combine
import UIKit

@MainActor
final class ImportExportViewModel: ObservableObject {
    @Published var toastMessage: String?
    @Published var selectedScope: ExportScope = .currentMonth
    @Published var isProcessing: Bool = false
    @Published var sharePayload: SharePayload?
    @Published var backupImportPreview: BackupImportPreview?
    @Published var csvImportPreview: CSVImportPreview?
    @Published var importResultDialog: ImportResultDialog?

    private let service: ImportExportService
    private var dismissToastTask: Task<Void, Never>?

    init(service: ImportExportService) {
        self.service = service
    }

    deinit {
        dismissToastTask?.cancel()
    }

    func exportCSV() {
        runExportAction(title: "CSV") { [service, selectedScope] in
            try await service.exportCSV(request: ExportRequest(scope: selectedScope, type: .csv))
        }
    }

    func exportBackup() {
        runExportAction(title: "备份 JSON") { [service, selectedScope] in
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

    func clearSharePayload() {
        sharePayload = nil
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
                showToast(kind.notImplementedToast)
            } catch {
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
                importResultDialog = ImportResultDialog(
                    title: "导入结果",
                    importedCount: result.importedCount,
                    skippedCount: result.skippedCount,
                    failedCount: result.failedCount
                )
            } catch ServiceError.notImplemented {
                showToast(kind.notImplementedToast)
            } catch {
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
                sharePayload = SharePayload(fileURL: result.fileURL)
                if let size = result.fileSizeBytes {
                    showToast("已生成\(title)（\(result.recordCount)条，\(formatFileSize(size))）")
                } else {
                    showToast("已生成\(title)（\(result.recordCount)条）")
                }
            } catch ServiceError.notImplemented {
                showToast("\(title)功能开发中")
            } catch {
                showToast("\(title)导出失败，请稍后重试")
            }
        }
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

        var notImplementedToast: String {
            switch self {
            case .backup:
                return "导入备份功能开发中"
            case .csv:
                return "导入 CSV 功能开发中"
            }
        }
    }
}

extension ImportExportViewModel {
    struct SharePayload: Identifiable {
        let id = UUID()
        let fileURL: URL
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
