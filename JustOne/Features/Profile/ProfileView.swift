import SwiftUI

struct ProfileView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @State private var showsDebug = false
    @State private var dailyReminderEnabled = true

    var body: some View {
        ZStack {
            JOColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: JOSpacing.xl) {
                    profileHero
                    settingsSection

                    #if DEBUG
                    JOPrimaryButton("Debug") {
                        showsDebug = true
                    }
                    #endif
                }
                .padding(.bottom, 140)
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.top, JOSpacing.md)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(true)
        }
        #if DEBUG
        .navigationDestination(isPresented: $showsDebug) {
            DebugView(
                repository: environment.container.repositories.bill,
                seedService: environment.container.services.seed
            )
        }
        #endif
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

                Image(systemName: "person.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(JOColors.profileRowSubtitle)
            }
            .padding(.top, 26)

            VStack(spacing: 4) {
                Text("Alex Doe")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(JOColors.profileName)
                Text("342 笔记录")
                    .font(JOTypography.caption)
                    .foregroundStyle(JOColors.profileMeta)
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: JOSpacing.lg) {
            NavigationLink {
                ProfilePlaceholderView(title: "类别设置")
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
                ProfilePlaceholderView(title: "设置")
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
        }
        .padding(.top, 36)
    }
}

private struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: JORadius.profileRow, style: .continuous)
                    .fill(JOColors.profileRowHighlight)
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: JORadius.profileRow, style: .continuous))
    }
}

private struct ProfilePlaceholderView: View {
    let title: String
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    var body: some View {
        VStack(spacing: JOSpacing.md) {
            Text(title)
                .font(JOTypography.title)
                .foregroundStyle(JOColors.textPrimary)
            Text("占位页")
                .font(JOTypography.body)
                .foregroundStyle(JOColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JOColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
        .onDisappear {
            tabBarVisibility?.setVisible(true)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(\.appEnvironment, .preview)
}
