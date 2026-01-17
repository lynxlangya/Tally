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
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(JOColors.textPrimary)
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: JORadius.input, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(JOTypography.headline)
                    .foregroundStyle(JOColors.textPrimary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                }
            }
            Spacer()
            JOAmountText(cents: amountCents, sign: amountSign, size: .small, color: amountColor)
        }
        .padding(.vertical, JOSpacing.sm)
        .padding(.horizontal, JOSpacing.md)
        .background(JOColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: JORadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: JORadius.card, style: .continuous)
                .stroke(JOColors.divider, lineWidth: 1)
        )
    }
}
