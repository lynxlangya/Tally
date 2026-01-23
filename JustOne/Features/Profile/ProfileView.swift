import SwiftUI

struct ProfileView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @State private var dailyReminderEnabled = true
    @State private var billCount: Int = 0
    @AppStorage("profileName") private var profileName: String = "Alex Doe"
    @AppStorage("profileAvatarData") private var avatarData: Data = Data()

    var body: some View {
        ZStack {
            JOColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: JOSpacing.xl) {
                    profileHero
                    settingsSection
                }
                .padding(.bottom, 140)
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.top, JOSpacing.md)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(true)
            loadBillCount()
        }
    }

    private var profileHero: some View {
        VStack(spacing: JOSpacing.md) {
            ZStack {
                Circle()
                    .fill(JOColors.fabGlow.opacity(0.12))
                    .frame(width: 138, height: 138)
                    .shadow(color: JOColors.fabGlow.opacity(0.35), radius: 28, x: 0, y: 8)
                    .shadow(color: JOColors.fabGlow.opacity(0.55), radius: 14, x: 0, y: 4)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                JOColors.background.opacity(0.9),
                                JOColors.surface.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 138, height: 138)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(JOColors.profileRowSubtitle)
                }
            }
            .padding(.top, 26)

            VStack(spacing: 4) {
                Text(profileName.isEmpty ? "Alex Doe" : profileName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(JOColors.profileName)
                Text("\(billCount) 笔记录")
                    .font(JOTypography.caption)
                    .foregroundStyle(JOColors.profileMeta)
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: JOSpacing.lg) {
            NavigationLink {
                CategoriesView(repository: environment.container.repositories.category)
            } label: {
                JOSettingRow(
                    title: "类别设置",
                    subtitle: "管理支出与收入分类",
                    systemImage: "square.grid.2x2.fill",
                    iconBackground: JOColors.profileRowIconBackground,
                    iconForeground: JOColors.profileRowTitle
                )
            }
            .buttonStyle(RowPressStyle())

            JOSettingRow(
                title: "每日提醒",
                subtitle: "每天晚上 8 点提醒",
                systemImage: "bell.fill",
                iconBackground: JOColors.profileRowIconBackground,
                iconForeground: JOColors.profileRowTitle,
                showsChevron: false,
                isOn: $dailyReminderEnabled
            )

            NavigationLink {
                SettingsView()
            } label: {
                JOSettingRow(
                    title: "设置",
                    subtitle: "通用设置",
                    systemImage: "gearshape.fill",
                    iconBackground: JOColors.profileRowIconBackground,
                    iconForeground: JOColors.profileRowTitle
                )
            }
            .buttonStyle(RowPressStyle())

            NavigationLink {
                PlaceholderView(title: "关于")
            } label: {
                JOSettingRow(
                    title: "关于",
                    subtitle: "版本信息",
                    systemImage: "info.circle.fill",
                    iconBackground: JOColors.profileRowIconBackground,
                    iconForeground: JOColors.profileRowTitle
                )
            }
            .buttonStyle(RowPressStyle())
        }
        .padding(.top, 36)
    }

    private func loadBillCount() {
        do {
            let bills = try environment.container.repositories.bill.list()
            billCount = bills.filter { $0.deletedAt == nil }.count
        } catch {
            billCount = 0
        }
    }

    private var avatarImage: UIImage? {
        guard !avatarData.isEmpty else { return nil }
        return UIImage(data: avatarData)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(\.appEnvironment, .preview)
}
