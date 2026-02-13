import Foundation
import Combine
import UIKit

@MainActor
final class ImportExportViewModel: ObservableObject {
    @Published var toastMessage: String?

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
        runAction(title: "导出 CSV") { [service] in
            _ = try await service.exportCSV(request: ExportRequest(scope: .allRecords, type: .csv))
        }
    }

    func exportBackup() {
        runAction(title: "导出备份") { [service] in
            _ = try await service.exportBackup(request: ExportRequest(scope: .allRecords, type: .backupJSON))
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

    private func runAction(title: String, operation: @escaping () async throws -> Void) {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()

        Task { [weak self] in
            guard let self else { return }
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
