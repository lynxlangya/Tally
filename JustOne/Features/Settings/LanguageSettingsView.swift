import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            header

            VStack(spacing: 0) {
                ForEach(Array(languageOptions.enumerated()), id: \.offset) { index, option in
                    LanguageOptionRow(option: option)
                        .allowsHitTesting(false)

                    if index < languageOptions.count - 1 {
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
            .padding(.top, JOSpacing.sm)

            Text("当前版本暂时不可修改，后续会完善语言更改功能。")
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)
                .padding(.top, JOSpacing.sm)

            Spacer()
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
            title: "语言设置",
            titleFont: JOTypography.headline,
            titleColor: JOColors.profileRowTitle
        ) {
            dismiss()
        }
    }
}

private struct LanguageOption: Identifiable {
    let id = UUID()
    let title: String
    let isSelected: Bool
}

private let languageOptions: [LanguageOption] = [
    LanguageOption(title: "跟随系统", isSelected: false),
    LanguageOption(title: "简体中文", isSelected: true),
    LanguageOption(title: "English", isSelected: false),
    LanguageOption(title: "日本語", isSelected: false),
    LanguageOption(title: "한국어", isSelected: false)
]

private struct LanguageOptionRow: View {
    let option: LanguageOption

    var body: some View {
        HStack {
            Text(option.title)
                .font(JOTypography.body)
                .foregroundStyle(JOColors.textPrimary)

            Spacer()

            Circle()
                .strokeBorder(
                    option.isSelected ? JOColors.accent : JOColors.textSecondary.opacity(0.6),
                    lineWidth: 2
                )
                .frame(width: 18, height: 18)
        }
        .padding(.horizontal, JOSpacing.lg)
        .padding(.vertical, JOSpacing.md + 5)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
    .environment(\.appEnvironment, .preview)
}
