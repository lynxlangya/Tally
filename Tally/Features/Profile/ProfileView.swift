import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled: Bool = false
    @AppStorage("profileName") private var profileName: String = "Mr. 琅邪"
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    @StateObject private var viewModel: ProfileViewModel
    @State private var showReminderSettingsPrompt = false
    @State private var suppressReminderToggle = false

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
        .onChange(of: dailyReminderEnabled) {
            guard !suppressReminderToggle else { return }
            handleReminderToggle(dailyReminderEnabled)
        }
        .alert("通知权限未开启", isPresented: $showReminderSettingsPrompt) {
            Button("取消", role: .cancel) { }
            Button("打开设置") {
                openAppSettings()
            }
        } message: {
            Text("请在系统设置中开启通知权限后再使用每日提醒。")
        }
    }

    private var identitySection: some View {
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
                    Text("\(viewModel.billCount) 笔")
                        .font(TallyType.num(12, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)

                    Circle()
                        .fill(Color.tallyInkGhost)
                        .frame(width: 3, height: 3)

                    Text("已记 \(viewModel.recordedDayCount) 天")
                        .font(TallyType.body(12, weight: .medium))
                        .foregroundStyle(Color.tallyInkDim)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, TallySpacing.s2)
        .padding(.top, TallySpacing.s2)
    }

    private var avatarTile: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 42 / 255, green: 37 / 255, blue: 32 / 255),
                        Color(red: 26 / 255, green: 24 / 255, blue: 21 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 72, height: 72)
            .overlay(
                TallyMark(size: 32, variant: .five, color: .tallyAccent, strokeWidth: 2.2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.tallyLineHi, lineWidth: 0.5)
            )
    }

    private var streakCard: some View {
        VStack(spacing: TallySpacing.s3) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("本周")
                Spacer()
                Text("已记 \(viewModel.weeklyRecordedCount) / 7 天")
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
                NavigationLink {
                    destinationView(for: row.destination)
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
                Text("每日提醒")
                    .font(TallyType.body(14, weight: .medium))
                    .foregroundStyle(Color.tallyInk)
                Text("每天 20:00 提醒")
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
            PlaceholderView(title: "关于 Tally")
        }
    }

    private var displayName: String {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Mr. 琅邪" : trimmed
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
            return "\(themeManager.settings.appearance.profileTitle) · \(themeManager.settings.accent.name)"
        case .language:
            return languageManager.selectedLanguage.title
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

private enum ProfileDestination: Hashable {
    case categories
    case recurring
    case importExport
    case theme
    case language
    case widget
    case about
}

private let profileRows: [ProfileRow] = [
    ProfileRow(icon: "cart.fill", title: "分类管理", subtitle: "支出 0 · 收入 0", destination: .categories),
    ProfileRow(icon: "repeat", title: "定时记账", subtitle: "0 条已启用", destination: .recurring),
    ProfileRow(icon: "doc.text.fill", title: "导入与导出", subtitle: "CSV · JSON 备份", destination: .importExport),
    ProfileRow(icon: "leaf.fill", title: "主题与外观", subtitle: "深色 · 朱砂", destination: .theme),
    ProfileRow(icon: "book.fill", title: "语言", subtitle: "简体中文", destination: .language),
    ProfileRow(icon: "tram.fill", title: "Widget", subtitle: "快捷记账 · 月度趋势", destination: .widget),
    ProfileRow(icon: "doc.text.fill", title: "关于 Tally", subtitle: "v1.0", destination: .about)
]

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
