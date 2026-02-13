import Foundation
import Combine
import UIKit

@MainActor
final class ImportExportViewModel: ObservableObject {
    @Published var toastMessage: String?
    @Published var selectedScope: ExportScope = .currentMonth
    @Published var isProcessing: Bool = false
    @Published var sharePayload: SharePayload?

    private let service: ImportExportService
    private var dismissToastTask: Task<Void, Never>?
    private static let placeholderFileURL = URL(fileURLWithPath: "/tmp/justone-placeholder")

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

    func importBackup() {
        runAction(title: "导入备份") { [service] in
            _ = try await service.previewImportBackup(from: Self.placeholderFileURL)
        }
    }

    func importCSV() {
        runAction(title: "导入 CSV") { [service] in
            _ = try await service.previewImportCSV(from: Self.placeholderFileURL)
        }
    }

    func clearSharePayload() {
        sharePayload = nil
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

    private func runAction(title: String, operation: @escaping () async throws -> Void) {
        guard !isProcessing else { return }
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        isProcessing = true

        Task { [weak self] in
            guard let self else { return }
            defer { isProcessing = false }

            do {
                try await operation()
                showToast("\(title)已完成")
            } catch ServiceError.notImplemented {
                showToast("\(title)功能开发中")
            } catch {
                showToast("\(title)暂不可用，请稍后重试")
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
}
