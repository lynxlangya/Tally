import SwiftUI

struct LegacySettingRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let iconBackground: Color
    let iconForeground: Color
    let showsChevron: Bool
    let isOn: Binding<Bool>?
    let backgroundColor: Color

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        iconBackground: Color,
        iconForeground: Color = LegacyColors.profileRowTitle,
        showsChevron: Bool = true,
        isOn: Binding<Bool>? = nil,
        backgroundColor: Color = .clear
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconBackground = iconBackground
        self.iconForeground = iconForeground
        self.showsChevron = showsChevron
        self.isOn = isOn
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        HStack(spacing: LegacySpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconForeground)
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(LegacyTypography.body)
                    .foregroundStyle(LegacyColors.profileRowTitle)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(LegacyTypography.caption)
                        .foregroundStyle(LegacyColors.profileRowSubtitle)
                }
            }

            Spacer()

            if let isOn {
                Toggle("", isOn: isOn)
                    .labelsHidden()
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LegacyColors.profileRowSubtitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LegacySpacing.lg)
        .padding(.vertical, LegacySpacing.md)
        .frame(minHeight: 64)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: LegacyRadius.profileRow, style: .continuous))
        .contentShape(Rectangle())
    }
}
