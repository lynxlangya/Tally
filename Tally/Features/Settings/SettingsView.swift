import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @Environment(\.appEnvironment) private var environment
    @ObservedObject private var languageManager = LanguageManager.shared

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
            title: TallyLocalization.text(.settings, locale: LanguageManager.shared.currentLocale),
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

    private var settingItems: [SettingsItem] {
        let locale = languageManager.currentLocale
        return [
            SettingsItem(title: TallyLocalization.text(.accountSettings, locale: locale), subtitle: nil, systemImage: "person.fill", destination: .account),
            SettingsItem(title: TallyLocalization.text(.importExport, locale: locale), subtitle: nil, systemImage: "arrow.up.arrow.down.circle.fill", destination: .importExport),
            SettingsItem(title: TallyLocalization.text(.recurring, locale: locale), subtitle: nil, systemImage: "clock.fill", destination: .recurring),
            SettingsItem(title: TallyLocalization.text(.widget, locale: locale), subtitle: nil, systemImage: "square.grid.2x2.fill", destination: .widget),
            SettingsItem(title: TallyLocalization.text(.themeSettings, locale: locale), subtitle: nil, systemImage: "paintpalette.fill", destination: .theme),
            SettingsItem(title: TallyLocalization.text(.language, locale: locale), subtitle: nil, systemImage: "globe", destination: .language)
        ]
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
            return TallyLocalization.text(.accountSettings, locale: LanguageManager.shared.currentLocale)
        case .importExport:
            return TallyLocalization.text(.importExport, locale: LanguageManager.shared.currentLocale)
        case .recurring:
            return TallyLocalization.text(.recurring, locale: LanguageManager.shared.currentLocale)
        case .widget:
            return TallyLocalization.text(.widget, locale: LanguageManager.shared.currentLocale)
        case .theme:
            return TallyLocalization.text(.themeSettings, locale: LanguageManager.shared.currentLocale)
        case .language:
            return TallyLocalization.text(.language, locale: LanguageManager.shared.currentLocale)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(\.appEnvironment, .preview)
}
