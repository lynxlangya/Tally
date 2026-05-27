import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showsToast = false

    var body: some View {
        ZStack {
            LegacyColors.background.ignoresSafeArea()

            VStack(spacing: LegacySpacing.lg) {
                header

                VStack(alignment: .leading, spacing: LegacySpacing.md) {
                    Text("外观模式")
                        .font(LegacyTypography.caption)
                        .foregroundStyle(LegacyColors.textSecondary)

                    GeometryReader { proxy in
                        let spacing: CGFloat = 12
                        let cardWidth = (proxy.size.width - spacing * 2) / 3
                        let cardHeight: CGFloat = 182

                        HStack(spacing: spacing) {
                            AppearanceOptionCard(
                                title: "浅色模式",
                                mode: .light,
                                isSelected: themeManager.settings.appearance == .light,
                                size: CGSize(width: cardWidth, height: cardHeight),
                                action: showComingSoon
                            )
                            AppearanceOptionCard(
                                title: "深色模式",
                                mode: .dark,
                                isSelected: themeManager.settings.appearance == .dark,
                                size: CGSize(width: cardWidth, height: cardHeight),
                                action: showComingSoon
                            )
                            AppearanceOptionCard(
                                title: "跟随系统",
                                mode: .system,
                                isSelected: themeManager.settings.appearance == .system,
                                size: CGSize(width: cardWidth, height: cardHeight),
                                action: showComingSoon
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .frame(height: 214)
                }

                Spacer()
            }
            .padding(.horizontal, LegacySpacing.lg)
            .padding(.top, LegacySpacing.lg)

            if showsToast {
                ToastView(text: "该功能即将上线")
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }

    private var header: some View {
        LegacyHeaderBar(
            title: "主题设置",
            titleFont: LegacyTypography.headline,
            titleColor: LegacyColors.profileRowTitle
        ) {
            dismiss()
        }
    }

    private func showComingSoon() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            showsToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showsToast = false
            }
        }
    }
}

private struct AppearanceOptionCard: View {
    let title: String
    let mode: AppearanceMode
    let isSelected: Bool
    let size: CGSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(LegacyColors.surface.opacity(0.6))
                        )

                    cardPreview

                    if isSelected {
                        selectionBadge
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(8)
                    }
                }
                .frame(width: size.width, height: size.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? LegacyColors.accent : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? LegacyColors.accent.opacity(0.28) : .clear, radius: 8, x: 0, y: 0)

                Text(title)
                    .font(LegacyTypography.caption)
                    .foregroundStyle(isSelected ? LegacyColors.accent : LegacyColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cardPreview: some View {
        switch mode {
        case .light:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .frame(width: size.width * 0.7, height: size.height * 0.78, alignment: .center)
                .overlay(
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: size.width * 0.45, height: 6)
                        Capsule()
                            .fill(Color.black.opacity(0.06))
                            .frame(width: size.width * 0.35, height: 4)
                    }
                )
        case .dark:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LegacyColors.background.opacity(0.9))
                .frame(width: size.width * 0.7, height: size.height * 0.78, alignment: .center)
                .overlay(
                    VStack(spacing: 10) {
                        Circle()
                            .fill(LegacyColors.accent.opacity(0.2))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(LegacyColors.accent)
                            )
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: size.width * 0.35, height: 6)
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: size.width * 0.25, height: 4)
                    }
                )
        case .system:
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LegacyColors.surface.opacity(0.85))
                .frame(width: size.width * 0.7, height: size.height * 0.78, alignment: .center)
                .overlay(
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
    }

    private var selectionBadge: some View {
        ZStack {
            Circle()
                .fill(LegacyColors.accent)
                .frame(width: 20, height: 20)
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(LegacyColors.accentForeground)
        }
        .shadow(color: LegacyColors.accent.opacity(0.35), radius: 4, x: 0, y: 0)
    }
}

private struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(LegacyTypography.caption)
            .foregroundStyle(LegacyColors.textPrimary)
            .padding(.horizontal, LegacySpacing.lg)
            .padding(.vertical, LegacySpacing.sm)
            .background(LegacyColors.surface.opacity(0.95))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(LegacyColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: LegacyShadows.card.color, radius: 6, x: 0, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, LegacySpacing.xl + 12)
            .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack {
        ThemeSettingsView()
    }
    .environment(\.appEnvironment, .preview)
}
