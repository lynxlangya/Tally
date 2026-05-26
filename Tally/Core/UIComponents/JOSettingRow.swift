import SwiftUI

struct JOSettingRow: View {
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
        iconForeground: Color = JOColors.profileRowTitle,
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
        HStack(spacing: JOSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconForeground)
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(JOTypography.body)
                    .foregroundStyle(JOColors.profileRowTitle)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.profileRowSubtitle)
                }
            }

            Spacer()

            if let isOn {
                Toggle("", isOn: isOn)
                    .labelsHidden()
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JOColors.profileRowSubtitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, JOSpacing.lg)
        .padding(.vertical, JOSpacing.md)
        .frame(minHeight: 64)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: JORadius.profileRow, style: .continuous))
        .contentShape(Rectangle())
    }
}
