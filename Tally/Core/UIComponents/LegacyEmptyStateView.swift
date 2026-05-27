import SwiftUI

struct LegacyEmptyStateView: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let iconSize: CGFloat
    let spacing: CGFloat

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String = "tray",
        iconSize: CGFloat = 28,
        spacing: CGFloat = 8
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconSize = iconSize
        self.spacing = spacing
    }

    var body: some View {
        VStack(spacing: spacing) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(LegacyColors.textSecondary)

            Text(title)
                .font(LegacyTypography.body)
                .foregroundStyle(LegacyColors.textPrimary.opacity(0.9))

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(LegacyTypography.caption)
                    .foregroundStyle(LegacyColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, LegacySpacing.lg)
    }
}

#Preview {
    ZStack {
        LegacyColors.background.ignoresSafeArea()
        LegacyEmptyStateView(title: "一根刻痕，一笔账。", subtitle: "记一笔")
            .padding()
    }
}
