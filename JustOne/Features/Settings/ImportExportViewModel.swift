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
        guard !isProcessing else { return }
        isProcessing = true

        Task { [weak self] in
            guard let self else { return }
            defer { isProcessing = false }

            do {
                let preview = try await service.previewImportBackup(from: fileURL)
                backupImportPreview = BackupImportPreview(fileURL: fileURL, preview: preview)
            } catch ServiceError.notImplemented {
                showToast("导入备份功能开发中")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    func confirmImportBackup() {
        guard let preview = backupImportPreview else { return }
        backupImportPreview = nil

        guard !isProcessing else { return }
        isProcessing = true

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        Task { [weak self] in
            guard let self else { return }
            defer { isProcessing = false }

            do {
                let result = try await service.importBackup(from: preview.fileURL)
                importResultDialog = ImportResultDialog(
                    title: "导入结果",
                    importedCount: result.importedCount,
                    skippedCount: result.skippedCount,
                    failedCount: result.failedCount
                )
            } catch ServiceError.notImplemented {
                showToast("导入备份功能开发中")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    func dismissImportBackupPreview() {
        backupImportPreview = nil
    }

    func prepareImportCSV(fileURL: URL) {
        guard !isProcessing else { return }
        isProcessing = true

        Task { [weak self] in
            guard let self else { return }
            defer { isProcessing = false }

            do {
                let preview = try await service.previewImportCSV(from: fileURL)
                csvImportPreview = CSVImportPreview(fileURL: fileURL, preview: preview)
            } catch ServiceError.notImplemented {
                showToast("导入 CSV 功能开发中")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    func confirmImportCSV() {
        guard let preview = csvImportPreview else { return }
        csvImportPreview = nil

        guard !isProcessing else { return }
        isProcessing = true

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        Task { [weak self] in
            guard let self else { return }
            defer { isProcessing = false }

            do {
                let result = try await service.importCSV(from: preview.fileURL)
                importResultDialog = ImportResultDialog(
                    title: "导入结果",
                    importedCount: result.importedCount,
                    skippedCount: result.skippedCount,
                    failedCount: result.failedCount
                )
            } catch ServiceError.notImplemented {
                showToast("导入 CSV 功能开发中")
            } catch {
                showToast(error.localizedDescription)
            }
        }
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
