import SwiftUI
import UIKit

struct ImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: ImportExportViewModel

    init(importExportService: ImportExportService) {
        _viewModel = StateObject(wrappedValue: ImportExportViewModel(service: importExportService))
    }

    var body: some View {
        ZStack {
            JOColors.background.ignoresSafeArea()

            VStack(spacing: JOSpacing.lg) {
                header

                exportScopePicker
                    .padding(.top, JOSpacing.sm)

                actionList

                boundaryHint

                Spacer()
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.top, JOSpacing.lg)

            if let toast = viewModel.toastMessage {
                ImportExportToastView(text: toast)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
        .sheet(item: $viewModel.sharePayload, onDismiss: {
            viewModel.clearSharePayload()
        }) { payload in
            ImportExportActivityView(activityItems: [payload.fileURL])
        }
    }

    private var header: some View {
        JOHeaderBar(
            title: "导入导出",
            titleFont: JOTypography.headline,
            titleColor: JOColors.profileRowTitle
        ) {
            dismiss()
        }
    }

    private var actionList: some View {
        VStack(spacing: 0) {
            ForEach(Array(actionItems.enumerated()), id: \.offset) { index, item in
                Button {
                    handleAction(item.kind)
                } label: {
                    JOSettingRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        systemImage: item.systemImage,
                        iconBackground: JOColors.profileRowIconBackground,
                        iconForeground: JOColors.profileRowTitle
                    )
                }
                .disabled(viewModel.isProcessing)
                .buttonStyle(RowPressStyle())

                if index < actionItems.count - 1 {
                    Divider()
                        .overlay(JOColors.cardBorder.opacity(0.35))
                        .padding(.horizontal, JOSpacing.lg)
                }
            }
        }
        .background(JOColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(JOColors.cardBorder, lineWidth: 1)
        )
        .shadow(
            color: JOShadows.card.color,
            radius: JOShadows.card.radius,
            x: JOShadows.card.x,
            y: JOShadows.card.y
        )
    }

    private var exportScopePicker: some View {
        VStack(alignment: .leading, spacing: JOSpacing.sm) {
            Text("导出范围")
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)

            HStack(spacing: JOSpacing.sm) {
                ForEach(ExportScope.allCases) { scope in
                    Button {
                        guard !viewModel.isProcessing else { return }
                        viewModel.selectedScope = scope
                    } label: {
                        Text(scope.title)
                            .font(JOTypography.caption)
                            .foregroundStyle(
                                viewModel.selectedScope == scope
                                    ? JOColors.accentForeground
                                    : JOColors.textSecondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, JOSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        viewModel.selectedScope == scope
                                            ? JOColors.accent
                                            : JOColors.surface
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(JOColors.cardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isProcessing)
                }
            }
        }
    }

    private var boundaryHint: some View {
        VStack(alignment: .leading, spacing: JOSpacing.xs) {
            Text("金额口径：CNY，固定 2 位小数，导入时禁止负数。")
            Text("时间口径：occurredAtUTC + occurredLocalDate。")
        }
        .font(JOTypography.caption)
        .foregroundStyle(JOColors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionItems: [ImportExportActionItem] {
        [
            .init(kind: .exportCSV, title: "导出 CSV", subtitle: "用于表格分析与二次处理", systemImage: "tablecells.fill"),
            .init(kind: .exportBackup, title: "导出备份（JSON）", subtitle: "完整备份账单与类别数据", systemImage: "externaldrive.fill"),
            .init(kind: .importBackup, title: "导入备份（JSON）", subtitle: "从备份文件恢复数据", systemImage: "square.and.arrow.down.fill"),
            .init(kind: .importCSV, title: "导入 CSV", subtitle: "从标准 CSV 导入账单", systemImage: "arrow.down.doc.fill")
        ]
    }

    private func handleAction(_ action: ImportExportAction) {
        switch action {
        case .exportCSV:
            viewModel.exportCSV()
        case .exportBackup:
            viewModel.exportBackup()
        case .importBackup:
            viewModel.importBackup()
        case .importCSV:
            viewModel.importCSV()
        }
    }
}

private struct ImportExportActionItem {
    let kind: ImportExportAction
    let title: String
    let subtitle: String
    let systemImage: String
}

private enum ImportExportAction {
    case exportCSV
    case exportBackup
    case importBackup
    case importCSV
}

private struct ImportExportToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(JOTypography.caption)
            .foregroundStyle(JOColors.textPrimary)
            .padding(.horizontal, JOSpacing.lg)
            .padding(.vertical, JOSpacing.sm)
            .background(JOColors.surface.opacity(0.95))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(JOColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: JOShadows.card.color, radius: 6, x: 0, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, JOSpacing.xl + 12)
            .allowsHitTesting(false)
    }
}

private struct ImportExportActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // no-op
    }
}

#Preview {
    NavigationStack {
        ImportExportView(importExportService: StubImportExportService())
    }
    .environment(\.appEnvironment, .preview)
}
