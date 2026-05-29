import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: ImportExportViewModel
    @State private var activeImporter: ImportFileKind?

    init(importExportService: ImportExportService, billRepository: BillRepository) {
        _viewModel = StateObject(wrappedValue: ImportExportViewModel(
            service: importExportService,
            billRepository: billRepository
        ))
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TallyNavHeader(title: TallyLocalization.text(.importExport, locale: LanguageManager.shared.currentLocale), onBack: { dismiss() })

                ScrollView {
                    VStack(spacing: TallySpacing.s6) {
                        currentDataBlock
                        exportScopePicker
                        actionCards
                        recentLogCard
                    }
                    .padding(.horizontal, TallySpacing.s4)
                    .padding(.top, TallySpacing.s2)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }

            if let toast = viewModel.toastMessage {
                ImportExportToastView(text: toast)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
            viewModel.reloadCurrentData()
        }
        .fileExporter(
            isPresented: Binding(
                get: { viewModel.exportPayload != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearExportPayload()
                    }
                }
            ),
            document: ImportExportDocument(data: viewModel.exportPayload?.data ?? Data()),
            contentType: viewModel.exportPayload?.contentType ?? .data,
            defaultFilename: viewModel.exportPayload?.defaultFilename ?? "Tally"
        ) { _ in
            viewModel.clearExportPayload()
        }
        .fileImporter(
            isPresented: Binding(
                get: { activeImporter != nil },
                set: { _ in }
            ),
            allowedContentTypes: activeImporter?.allowedTypes ?? [.data],
            allowsMultipleSelection: false
        ) { result in
            guard let importer = activeImporter else { return }
            defer { activeImporter = nil }
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                switch importer {
                case .backup:
                    viewModel.prepareImportBackup(fileURL: url)
                case .csv:
                    viewModel.prepareImportCSV(fileURL: url)
                }
            case .failure:
                break
            }
        }
        .alert(item: $viewModel.importResultDialog) { dialog in
            Alert(
                title: Text(dialog.title),
                message: Text(dialog.message),
                dismissButton: .default(Text(TallyLocalization.text(.gotIt, locale: LanguageManager.shared.currentLocale))) {
                    viewModel.dismissImportResultDialog()
                }
            )
        }
        .confirmationDialog(
            TallyLocalization.text("import_preflight", locale: LanguageManager.shared.currentLocale),
            isPresented: Binding(
                get: { viewModel.backupImportPreview != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.dismissImportBackupPreview()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(TallyLocalization.text("confirm_import", locale: LanguageManager.shared.currentLocale)) {
                viewModel.confirmImportBackup()
            }
            Button(TallyLocalization.text(.cancel, locale: LanguageManager.shared.currentLocale), role: .cancel) {
                viewModel.dismissImportBackupPreview()
            }
        } message: {
            Text(viewModel.backupImportPreviewMessage)
        }
        .confirmationDialog(
            TallyLocalization.text("import_preflight", locale: LanguageManager.shared.currentLocale),
            isPresented: Binding(
                get: { viewModel.csvImportPreview != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.dismissImportCSVPreview()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(TallyLocalization.text("confirm_import", locale: LanguageManager.shared.currentLocale)) {
                viewModel.confirmImportCSV()
            }
            Button(TallyLocalization.text(.cancel, locale: LanguageManager.shared.currentLocale), role: .cancel) {
                viewModel.dismissImportCSVPreview()
            }
        } message: {
            Text(viewModel.csvImportPreviewMessage)
        }
    }

    private var currentDataBlock: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s2) {
            Eyebrow(TallyLocalization.text("current_data", locale: LanguageManager.shared.currentLocale))

            HStack(alignment: .firstTextBaseline, spacing: TallySpacing.s2) {
                Text("\(viewModel.currentRecordCount)")
                    .font(TallyType.num(32, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                Text(TallyLocalization.text("records_unit", locale: LanguageManager.shared.currentLocale))
                    .font(TallyType.body(13, weight: .medium))
                    .foregroundStyle(Color.tallyInkDim)
            }

            Text(viewModel.dateRangeSubtitle)
                .font(TallyType.body(12, weight: .medium))
                .foregroundStyle(Color.tallyInkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TallySpacing.s2)
    }

    private var exportScopePicker: some View {
        HStack(spacing: TallySpacing.s3) {
            Text(TallyLocalization.text("export_scope", locale: LanguageManager.shared.currentLocale))
                .font(TallyType.body(12, weight: .medium))
                .foregroundStyle(Color.tallyInkFaint)

            Spacer(minLength: 0)

            Segmented(
                value: $viewModel.selectedScope,
                options: ExportScope.allCases.map { ($0, $0.title) },
                size: .sm
            )
            .disabled(viewModel.isProcessing)
        }
    }

    private var actionCards: some View {
        VStack(spacing: 10) {
            ForEach(actionItems) { item in
                Button {
                    handleAction(item.kind)
                } label: {
                    ImportExportActionCard(item: item)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessing)
            }
        }
    }

    private var recentLogCard: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s3) {
            Eyebrow(TallyLocalization.text("recent_records", locale: LanguageManager.shared.currentLocale))

            VStack(spacing: 0) {
                if recentLogs.isEmpty {
                    Text(TallyLocalization.text("no_import_export_logs", locale: LanguageManager.shared.currentLocale))
                        .font(TallyType.body(12, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(TallySpacing.s4)
                } else {
                    ForEach(Array(recentLogs.enumerated()), id: \.element.id) { index, log in
                        ImportExportLogRow(log: log, isLast: index == recentLogs.count - 1)
                    }
                }
            }
            .background(Color.tallySurface)
            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .stroke(Color.tallyLine, lineWidth: 0.5)
            )
        }
    }

    private var recentLogs: [ImportExportLog] {
        Array(viewModel.logs.prefix(3))
    }

    private var actionItems: [ImportExportActionItem] {
        [
            .init(
                kind: .exportCSV,
                title: TallyLocalization.text("export_csv", locale: LanguageManager.shared.currentLocale),
                subtitle: TallyLocalization.text("export_csv_subtitle", locale: LanguageManager.shared.currentLocale),
                icon: "square.and.arrow.up",
                style: .primary
            ),
            .init(
                kind: .exportBackup,
                title: TallyLocalization.text("export_backup_json", locale: LanguageManager.shared.currentLocale),
                subtitle: TallyLocalization.text("export_backup_json_subtitle", locale: LanguageManager.shared.currentLocale),
                icon: "square.and.arrow.up",
                style: .neutral
            ),
            .init(
                kind: .importBackup,
                title: TallyLocalization.text("import_backup", locale: LanguageManager.shared.currentLocale),
                subtitle: TallyLocalization.text("import_backup_subtitle", locale: LanguageManager.shared.currentLocale),
                icon: "square.and.arrow.down",
                style: .neutral
            ),
            .init(
                kind: .importCSV,
                title: TallyLocalization.text("import_csv", locale: LanguageManager.shared.currentLocale),
                subtitle: TallyLocalization.text("import_csv_subtitle", locale: LanguageManager.shared.currentLocale),
                icon: "square.and.arrow.down",
                style: .neutral
            )
        ]
    }

    private func handleAction(_ action: ImportExportAction) {
        switch action {
        case .exportCSV:
            viewModel.exportCSV()
        case .exportBackup:
            viewModel.exportBackup()
        case .importBackup:
            activeImporter = .backup
        case .importCSV:
            activeImporter = .csv
        }
    }
}

private struct ImportExportActionCard: View {
    let item: ImportExportActionItem

    var body: some View {
        HStack(spacing: TallySpacing.s3) {
            TallyIcon(name: item.icon, size: 18)
                .foregroundStyle(item.style.iconForeground)
                .frame(width: 36, height: 36)
                .background(item.style.iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(TallyType.body(15, weight: .semibold))
                    .foregroundStyle(item.style.titleColor)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.tallyInkFaint)
        }
        .padding(TallySpacing.s4)
        .background(item.style.background)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                .stroke(item.style.border, lineWidth: 0.5)
        )
    }
}

private struct ImportExportLogRow: View {
    let log: ImportExportLog
    let isLast: Bool

    var body: some View {
        HStack(spacing: TallySpacing.s3) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(log.title)
                    .font(TallyType.body(13, weight: .medium))
                    .foregroundStyle(Color.tallyInk)
                    .lineLimit(1)

                Text(metaText)
                    .font(TallyType.body(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.tallyInkGhost)
        }
        .padding(.horizontal, TallySpacing.s4)
        .padding(.vertical, TallySpacing.s3)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.tallyLine)
                    .frame(height: 0.5)
                    .padding(.leading, 26)
            }
        }
    }

    private var statusColor: Color {
        switch log.status {
        case .success:
            return .catMoss
        case .warning:
            return .catOchre
        case .failure:
            return .catTerracotta
        }
    }

    private var metaText: String {
        let locale = LanguageManager.shared.currentLocale
        return TallyLocalization.format(
            "import_export_log_meta",
            locale: locale,
            Self.dateText(log.createdAt, locale: locale),
            Self.timeText(log.createdAt, locale: locale),
            log.count,
            log.errors
        )
    }

    private static func dateText(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("yMd")
        return formatter.string(from: date)
    }

    private static func timeText(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

private struct ImportExportActionItem: Identifiable {
    var id: ImportExportAction { kind }

    let kind: ImportExportAction
    let title: String
    let subtitle: String
    let icon: String
    let style: ImportExportActionStyle
}

private enum ImportExportActionStyle {
    case primary
    case neutral

    var background: Color {
        switch self {
        case .primary:
            return .tallyAccentTint
        case .neutral:
            return .tallySurface
        }
    }

    var border: Color {
        switch self {
        case .primary:
            return .tallyAccent.opacity(0.28)
        case .neutral:
            return .tallyLine
        }
    }

    var iconBackground: Color {
        switch self {
        case .primary:
            return .tallyAccent
        case .neutral:
            return .tallySurface2
        }
    }

    var iconForeground: Color {
        switch self {
        case .primary:
            return .tallyAccentInk
        case .neutral:
            return .tallyInkDim
        }
    }

    var titleColor: Color {
        switch self {
        case .primary:
            return .tallyAccent
        case .neutral:
            return .tallyInk
        }
    }
}

private enum ImportExportAction: Hashable {
    case exportCSV
    case exportBackup
    case importBackup
    case importCSV
}

private enum ImportFileKind {
    case backup
    case csv

    var allowedTypes: [UTType] {
        switch self {
        case .backup:
            return [.json]
        case .csv:
            return [.commaSeparatedText, .plainText]
        }
    }
}

private struct ImportExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .json, .data] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct ImportExportToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(TallyType.body(12, weight: .medium))
            .foregroundStyle(Color.tallyInk)
            .padding(.horizontal, TallySpacing.s4)
            .padding(.vertical, TallySpacing.s2)
            .background(Color.tallySurface.opacity(0.96))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.tallyLine, lineWidth: 0.5)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 72)
            .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        ImportExportView(
            importExportService: StubImportExportService(),
            billRepository: MockBillRepository()
        )
    }
    .environment(\.appEnvironment, .preview)
}
