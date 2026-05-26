import SwiftUI

struct JOEmptyStateView: View {
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
                .foregroundStyle(JOColors.textSecondary)

            Text(title)
                .font(JOTypography.body)
                .foregroundStyle(JOColors.textPrimary.opacity(0.9))

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(JOTypography.caption)
                    .foregroundStyle(JOColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, JOSpacing.lg)
    }
}

#Preview {
    ZStack {
        JOColors.background.ignoresSafeArea()
        JOEmptyStateView(title: "暂无账单", subtitle: "点击 + 记一笔")
            .padding()
    }
}
