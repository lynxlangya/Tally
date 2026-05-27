import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility

    var body: some View {
        VStack(spacing: LegacySpacing.lg) {
            header

            VStack(spacing: 0) {
                ForEach(Array(languageOptions.enumerated()), id: \.offset) { index, option in
                    LanguageOptionRow(option: option)
                        .allowsHitTesting(false)

                    if index < languageOptions.count - 1 {
                        Divider()
                            .overlay(LegacyColors.cardBorder.opacity(0.35))
                            .padding(.horizontal, LegacySpacing.lg)
                    }
                }
            }
            .background(LegacyColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LegacyColors.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: LegacyShadows.card.color,
                radius: LegacyShadows.card.radius,
                x: LegacyShadows.card.x,
                y: LegacyShadows.card.y
            )
            .padding(.top, LegacySpacing.sm)

            Text("当前版本暂时不可修改，后续会完善语言更改功能。")
                .font(LegacyTypography.caption)
                .foregroundStyle(LegacyColors.textSecondary)
                .padding(.top, LegacySpacing.sm)

            Spacer()
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
            title: "语言设置",
            titleFont: LegacyTypography.headline,
            titleColor: LegacyColors.profileRowTitle
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
                .font(LegacyTypography.body)
                .foregroundStyle(LegacyColors.textPrimary)

            Spacer()

            Circle()
                .strokeBorder(
                    option.isSelected ? LegacyColors.accent : LegacyColors.textSecondary.opacity(0.6),
                    lineWidth: 2
                )
                .frame(width: 18, height: 18)
        }
        .padding(.horizontal, LegacySpacing.lg)
        .padding(.vertical, LegacySpacing.md + 5)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
    .environment(\.appEnvironment, .preview)
}
