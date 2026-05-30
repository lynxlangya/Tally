import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled: Bool = false
    @AppStorage(ProfileIdentityStore.nameKey) private var profileName: String = ProfileIdentityStore.defaultName
    @AppStorage(ProfileIdentityStore.avatarDataKey) private var avatarData: Data = Data()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    @StateObject private var viewModel: ProfileViewModel
    @State private var showReminderSettingsPrompt = false
    @State private var suppressReminderToggle = false
    @State private var selectedDestination: ProfileDestination?

    private let reminderHour = 20
    private let reminderMinute = 0

    init(
        billRepository: BillRepository,
        categoryRepository: CategoryRepository,
        recurringRepository: RecurringRepository
    ) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            billRepository: billRepository,
            categoryRepository: categoryRepository,
            recurringRepository: recurringRepository
        ))
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    identitySection
                    streakCard
                        .padding(.top, 22)
                    settingsGroup
                        .padding(.top, TallySpacing.s6)
                    reminderControl
                        .padding(.top, TallySpacing.s5)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(TallyType.body(12, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.82))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, TallySpacing.s4)
                    }
                }
                .padding(.horizontal, TallySpacing.s4)
                .padding(.top, TallySpacing.s3)
                .padding(.bottom, 132)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(true)
            viewModel.load()
            Task { await syncReminderAuthorization() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .billDidChange)) { _ in
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .categoryDidChange)) { _ in
            viewModel.load()
        }
        .onChange(of: dailyReminderEnabled) {
            guard !suppressReminderToggle else { return }
            handleReminderToggle(dailyReminderEnabled)
        }
        .alert(TallyLocalization.text("notification_permission_title", locale: languageManager.currentLocale), isPresented: $showReminderSettingsPrompt) {
            Button(TallyLocalization.text(.cancel, locale: languageManager.currentLocale), role: .cancel) { }
            Button(TallyLocalization.text("open_settings", locale: languageManager.currentLocale)) {
                openAppSettings()
            }
        } message: {
            Text(TallyLocalization.text("notification_permission_message", locale: languageManager.currentLocale))
        }
        .navigationDestination(item: $selectedDestination) { destination in
            destinationView(for: destination)
        }
    }

    private var identitySection: some View {
        Button {
            selectedDestination = .account
        } label: {
            HStack(alignment: .center, spacing: TallySpacing.s4) {
                avatarTile

                VStack(alignment: .leading, spacing: TallySpacing.s2) {
                    Text(displayName)
                        .font(TallyType.display(22, weight: .semibold))
                        .tracking(-0.44)
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    HStack(spacing: 10) {
                        Text(TallyLocalization.format(.billCount, locale: languageManager.currentLocale, viewModel.billCount))
                            .font(TallyType.num(12, weight: .semibold))
                            .foregroundStyle(Color.tallyInk)

                        Circle()
                            .fill(Color.tallyInkGhost)
                            .frame(width: 3, height: 3)

                        Text(TallyLocalization.format(.billRecordedDays, locale: languageManager.currentLocale, viewModel.recordedDayCount))
                            .font(TallyType.body(12, weight: .medium))
                            .foregroundStyle(Color.tallyInkDim)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.tallyInkFaint)
                    .frame(width: 24, height: 24)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TallyLocalization.text(.accountSettings, locale: languageManager.currentLocale))
        .padding(.horizontal, TallySpacing.s2)
        .padding(.top, TallySpacing.s2)
    }

    private var avatarTile: some View {
        ProfileAvatarView(
            avatarData: avatarData,
            size: 72,
            cornerRadius: 22,
            appIcon: themeManager.settings.appIcon,
            accent: themeManager.settings.accent.color,
            showsEditBadge: true
        )
    }

    private var streakCard: some View {
        VStack(spacing: TallySpacing.s3) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow(TallyLocalization.text(.week, locale: languageManager.currentLocale))
                Spacer()
                Text(TallyLocalization.format("recorded_week_progress", locale: languageManager.currentLocale, viewModel.weeklyRecordedCount))
                    .font(TallyType.body(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(viewModel.streakDays) { day in
                    Capsule(style: .continuous)
                        .fill(streakBarColor(for: day))
                        .frame(maxWidth: .infinity)
                        .frame(height: streakBarHeight(for: day))
                }
            }
            .frame(height: 28, alignment: .bottom)

            HStack(spacing: 0) {
                ForEach(viewModel.streakDays) { day in
                    Text(day.label)
                        .font(TallyType.body(10, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, TallySpacing.s4)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }

    private var settingsGroup: some View {
        VStack(spacing: 0) {
            ForEach(Array(profileRows.enumerated()), id: \.element.id) { index, row in
                Button {
                    selectedDestination = row.destination
                } label: {
                    ProfileSettingsRow(
                        icon: row.icon,
                        title: row.title,
                        subtitle: subtitle(for: row),
                        chip: chip(for: row),
                        isLast: index == profileRows.count - 1
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }

    private var reminderControl: some View {
        Toggle(isOn: $dailyReminderEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text(TallyLocalization.text(.dailyReminder, locale: languageManager.currentLocale))
                    .font(TallyType.body(14, weight: .medium))
                    .foregroundStyle(Color.tallyInk)
                Text(TallyLocalization.text("daily_reminder_time", locale: languageManager.currentLocale))
                    .font(TallyType.body(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }
        }
        .tint(Color.tallyAccent)
        .padding(.horizontal, TallySpacing.s4)
        .padding(.vertical, TallySpacing.s3)
        .background(Color.tallySurface2)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous))
    }

    @ViewBuilder
    private func destinationView(for destination: ProfileDestination) -> some View {
        switch destination {
        case .account:
            AccountSettingsView()
        case .categories:
            CategoriesView(repository: environment.container.repositories.category)
        case .recurring:
            RecurringBillsView(
                recurringRepository: environment.container.repositories.recurring,
                categoryRepository: environment.container.repositories.category,
                billRepository: environment.container.repositories.bill
            )
        case .importExport:
            ImportExportView(
                importExportService: environment.container.services.importExport,
                billRepository: environment.container.repositories.bill
            )
        case .theme:
            ThemeSettingsView()
        case .language:
            LanguageSettingsView()
        case .widget:
            WidgetPreviewView()
        case .about:
            AboutTallyView {
                selectedDestination = nil
            }
        }
    }

    private var displayName: String {
        ProfileIdentityStore.displayName(for: profileName)
    }

    private func subtitle(for row: ProfileRow) -> String {
        switch row.destination {
        case .categories:
            return viewModel.categorySubtitle
        case .recurring:
            return viewModel.recurringSubtitle
        case .about:
            return versionSubtitle
        case .theme:
            return "\(themeManager.settings.appearance.profileTitle) · \(themeManager.settings.accent.localizedName)"
        case .language:
            return languageManager.selectedLanguage.nativeName
        default:
            return row.subtitle
        }
    }

    private func chip(for row: ProfileRow) -> String? {
        guard row.destination == .recurring else { return row.chip }
        return viewModel.nextRecurringChip
    }

    private var versionSubtitle: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let normalized = version?.trimmingCharacters(in: .whitespacesAndNewlines)
        return "v\((normalized?.isEmpty == false ? normalized : nil) ?? "1.0")"
    }

    private var profileRows: [ProfileRow] {
        let locale = languageManager.currentLocale
        return [
            ProfileRow(
                icon: "shopping-cart",
                title: TallyLocalization.text("category_management", locale: locale),
                subtitle: "0",
                destination: .categories
            ),
            ProfileRow(
                icon: "repeat",
                title: TallyLocalization.text(.recurring, locale: locale),
                subtitle: "0",
                destination: .recurring
            ),
            ProfileRow(
                icon: "file-text",
                title: TallyLocalization.text(.importExport, locale: locale),
                subtitle: TallyLocalization.text("language_backup_subtitle", locale: locale),
                destination: .importExport
            ),
            ProfileRow(
                icon: "leaf",
                title: TallyLocalization.text("theme_appearance", locale: locale),
                subtitle: themeManager.settings.appearance.profileTitle,
                destination: .theme
            ),
            ProfileRow(
                icon: "globe",
                title: TallyLocalization.text(.language, locale: locale),
                subtitle: languageManager.selectedLanguage.nativeName,
                destination: .language
            ),
            ProfileRow(
                icon: "bell",
                title: TallyLocalization.text(.widget, locale: locale),
                subtitle: TallyLocalization.text("widget_profile_subtitle", locale: locale),
                destination: .widget
            ),
            ProfileRow(
                icon: "info",
                title: TallyLocalization.text("about_tally", locale: locale),
                subtitle: "v1.0",
                destination: .about
            )
        ]
    }

    private func streakBarHeight(for day: ProfileViewModel.StreakDay) -> CGFloat {
        guard day.count > 0 else { return 4 }
        return max(4, CGFloat(day.normalizedHeight) * 28)
    }

    private func streakBarColor(for day: ProfileViewModel.StreakDay) -> Color {
        if day.isRecorded {
            return .tallyAccent
        }
        return .tallyInkGhost.opacity(0.4)
    }

    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            Task { await attemptEnableReminder() }
        } else {
            ReminderNotificationManager.shared.cancelDailyReminder()
        }
    }

    @MainActor
    private func attemptEnableReminder() async {
        let status = await ReminderNotificationManager.shared.authorizationStatus()
        switch status {
        case .notDetermined:
            let granted = await ReminderNotificationManager.shared.requestAuthorization()
            if granted {
                await ReminderNotificationManager.shared.scheduleDailyReminder(
                    hour: reminderHour,
                    minute: reminderMinute
                )
                updateReminderToggle(true)
            } else {
                updateReminderToggle(false)
                showReminderSettingsPrompt = true
            }
        case .denied:
            updateReminderToggle(false)
            showReminderSettingsPrompt = true
        case .authorized, .provisional, .ephemeral:
            await ReminderNotificationManager.shared.scheduleDailyReminder(
                hour: reminderHour,
                minute: reminderMinute
            )
            updateReminderToggle(true)
        @unknown default:
            updateReminderToggle(false)
        }
    }

    @MainActor
    private func syncReminderAuthorization() async {
        let status = await ReminderNotificationManager.shared.authorizationStatus()
        if dailyReminderEnabled {
            switch status {
            case .authorized, .provisional, .ephemeral:
                await ReminderNotificationManager.shared.scheduleDailyReminder(
                    hour: reminderHour,
                    minute: reminderMinute
                )
            default:
                updateReminderToggle(false)
            }
        }
    }

    private func updateReminderToggle(_ enabled: Bool) {
        suppressReminderToggle = true
        dailyReminderEnabled = enabled
        DispatchQueue.main.async {
            suppressReminderToggle = false
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let chip: String?
    let isLast: Bool

    var body: some View {
        HStack(spacing: 14) {
            TallyIcon(name: icon, size: 16)
                .foregroundStyle(Color.tallyInkDim)
                .frame(width: 32, height: 32)
                .background(Color.tallySurface2)
                .clipShape(RoundedRectangle(cornerRadius: TallyRadii.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TallyType.body(14, weight: .medium))
                    .foregroundStyle(Color.tallyInk)
                    .lineLimit(1)

                Text(subtitle)
                    .font(TallyType.body(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let chip {
                Chip(chip, tone: .outline, size: .xs)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.tallyInkFaint)
        }
        .padding(14)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.tallyLine)
                    .frame(height: 0.5)
                    .padding(.leading, 62)
            }
        }
    }
}

private struct ProfileRow: Identifiable {
    let id: ProfileDestination
    let icon: String
    let title: String
    let subtitle: String
    let chip: String?
    let destination: ProfileDestination

    init(icon: String, title: String, subtitle: String, chip: String? = nil, destination: ProfileDestination) {
        self.id = destination
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.chip = chip
        self.destination = destination
    }
}

private enum ProfileDestination: Hashable, Identifiable {
    case account
    case categories
    case recurring
    case importExport
    case theme
    case language
    case widget
    case about

    var id: Self { self }
}

#Preview {
    NavigationStack {
        ProfileView(
            billRepository: MockBillRepository(),
            categoryRepository: MockCategoryRepository(),
            recurringRepository: NoopRecurringRepository()
        )
    }
    .environment(\.appEnvironment, .preview)
}
