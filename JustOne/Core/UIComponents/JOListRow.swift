import SwiftUI

struct JOListRow: View {
    let iconName: String
    let iconBackground: Color
    let title: String
    let subtitle: String?
    let amountCents: Int
    let amountSign: String?
    let amountColor: Color

    init(
        iconName: String,
        iconBackground: Color,
        title: String,
        subtitle: String? = nil,
        amountCents: Int,
        amountSign: String? = nil,
        amountColor: Color = JOColors.textPrimary
    ) {
        self.iconName = iconName
        self.iconBackground = iconBackground
        self.title = title
        self.subtitle = subtitle
        self.amountCents = amountCents
        self.amountSign = amountSign
        self.amountColor = amountColor
    }

    var body: some View {
        HStack(spacing: JOSpacing.md) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(JOColors.textPrimary)
                .frame(width: 46, height: 46)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: JORadius.icon, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(JOTypography.body)
                    .foregroundStyle(JOColors.textPrimary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                }
            }
            Spacer()
            JOAmountText(cents: amountCents, sign: amountSign, size: .row, color: amountColor)
        }
        .padding(.vertical, JOSpacing.sm)
        .padding(.horizontal, JOSpacing.lg)
        .frame(minHeight: 72)
        .background(JOColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: JORadius.row, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JORadius.row, style: .continuous)
                .stroke(JOColors.cardBorder, lineWidth: 1)
        )
        .shadow(
            color: JOShadows.card.color,
            radius: JOShadows.card.radius,
            x: JOShadows.card.x,
            y: JOShadows.card.y
        )
    }
}
