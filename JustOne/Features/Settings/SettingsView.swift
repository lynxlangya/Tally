import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            header

            ScrollView {
                VStack(spacing: JOSpacing.lg) {
                    ForEach(settingItems) { item in
                        NavigationLink {
                            PlaceholderView(title: item.destination.title)
                        } label: {
                            JOSettingRow(
                                title: item.title,
                                subtitle: item.subtitle,
                                systemImage: item.systemImage,
                                iconBackground: JOColors.profileRowIconBackground,
                                iconForeground: JOColors.profileRowTitle
                            )
                        }
                        .buttonStyle(RowPressStyle())
                    }
                }
                .padding(.bottom, 120)
            }
        }
        .padding(.horizontal, JOSpacing.lg)
        .padding(.top, JOSpacing.lg)
        .background(JOColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }

    private var header: some View {
        JOHeaderBar(
            title: "通用设置",
            titleFont: JOTypography.headline,
            titleColor: JOColors.profileRowTitle
        ) {
            dismiss()
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
    case export
    case lock
    case recurring
    case widget
    case theme
    case language

    var title: String {
        switch self {
        case .account:
            return "账号设置"
        case .export:
            return "导出数据"
        case .lock:
            return "解锁密码"
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
    SettingsItem(title: "导出数据", subtitle: nil, systemImage: "square.and.arrow.up", destination: .export),
    SettingsItem(title: "解锁密码", subtitle: nil, systemImage: "lock.fill", destination: .lock),
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
