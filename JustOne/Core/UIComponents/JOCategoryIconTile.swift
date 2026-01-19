import SwiftUI

struct JOCategoryIconTile: View {
    let iconName: String
    let title: String
    let iconColor: Color
    let size: CGFloat
    let iconSize: CGFloat
    let showsTitle: Bool
    let backgroundColor: Color
    let titleFont: Font
    let titleColor: Color
    let shadowOpacity: Double
    let spacing: CGFloat

    init(
        iconName: String,
        title: String,
        iconColor: Color,
        size: CGFloat = 56,
        iconSize: CGFloat = 24,
        showsTitle: Bool = true,
        backgroundColor: Color = JOColors.categoryItemBackground,
        titleFont: Font = JOTypography.caption,
        titleColor: Color = JOColors.textSecondary,
        shadowOpacity: Double = 0.2,
        spacing: CGFloat = JOSpacing.sm
    ) {
        self.iconName = iconName
        self.title = title
        self.iconColor = iconColor
        self.size = size
        self.iconSize = iconSize
        self.showsTitle = showsTitle
        self.backgroundColor = backgroundColor
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.shadowOpacity = shadowOpacity
        self.spacing = spacing
    }

    var body: some View {
        VStack(spacing: spacing) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)

                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .shadow(color: iconColor.opacity(shadowOpacity), radius: 4, x: 0, y: 0)
            }

            if showsTitle {
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
            }
        }
    }
}
