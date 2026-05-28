import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        VStack(spacing: LegacySpacing.lg) {
            header

            ScrollView {
                VStack(spacing: LegacySpacing.lg) {
                    ForEach(settingItems) { item in
                        NavigationLink {
                            destinationView(for: item.destination)
                        } label: {
                            LegacySettingRow(
                                title: item.title,
                                subtitle: item.subtitle,
                                systemImage: item.systemImage,
                                iconBackground: LegacyColors.profileRowIconBackground,
                                iconForeground: LegacyColors.profileRowTitle
                            )
                        }
                        .buttonStyle(RowPressStyle())
                    }
                }
                .padding(.bottom, 120)
            }
        }
        .padding(.horizontal, LegacySpacing.lg)
        .padding(.top, LegacySpacing.lg)
        .background(LegacyColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }

    private var header: some View {
        LegacyHeaderBar(
            title: "通用设置",
            titleFont: LegacyTypography.headline,
            titleColor: LegacyColors.profileRowTitle
        ) {
            dismiss()
        }
    }

    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .account:
            AccountSettingsView()
        case .language:
            LanguageSettingsView()
        case .theme:
            ThemeSettingsView()
        case .importExport:
            ImportExportView(
                importExportService: environment.container.services.importExport,
                billRepository: environment.container.repositories.bill
            )
        case .recurring:
            RecurringBillsView(
                recurringRepository: environment.container.repositories.recurring,
                categoryRepository: environment.container.repositories.category,
                billRepository: environment.container.repositories.bill
            )
        case .widget:
            WidgetPreviewView()
        }
    }
}

private struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let systemImage: String
    let destination: SettingsDestination
}

private enum SettingsDestination: String {
    case account
    case importExport
    case recurring
    case widget
    case theme
    case language

    var title: String {
        switch self {
        case .account:
            return "账号设置"
        case .importExport:
            return "导入导出"
        case .recurring:
            return "定时记账"
        case .widget:
            return "桌面小组件"
        case .theme:
            return "主题设置"
        case .language:
            return "语言设置"
        }
    }
}

private let settingItems: [SettingsItem] = [
    SettingsItem(title: "账号设置", subtitle: nil, systemImage: "person.fill", destination: .account),
    SettingsItem(title: "导入导出", subtitle: nil, systemImage: "arrow.up.arrow.down.circle.fill", destination: .importExport),
    SettingsItem(title: "定时记账", subtitle: nil, systemImage: "clock.fill", destination: .recurring),
    SettingsItem(title: "桌面小组件", subtitle: nil, systemImage: "square.grid.2x2.fill", destination: .widget),
    SettingsItem(title: "主题设置", subtitle: nil, systemImage: "paintpalette.fill", destination: .theme),
    SettingsItem(title: "语言设置", subtitle: nil, systemImage: "globe", destination: .language)
]

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(\.appEnvironment, .preview)
}
