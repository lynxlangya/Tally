import SwiftUI

struct LegacyHeaderBar: View {
    let title: String?
    let titleFont: Font
    let titleColor: Color
    let titleTracking: CGFloat?
    let trailingWidth: CGFloat
    let showsTrailingPlaceholder: Bool
    let onBack: () -> Void

    init(
        title: String? = nil,
        titleFont: Font = LegacyTypography.headline,
        titleColor: Color = LegacyColors.textSecondary,
        titleTracking: CGFloat? = nil,
        trailingWidth: CGFloat = 36,
        showsTrailingPlaceholder: Bool = true,
        onBack: @escaping () -> Void
    ) {
        self.title = title
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.titleTracking = titleTracking
        self.trailingWidth = trailingWidth
        self.showsTrailingPlaceholder = showsTrailingPlaceholder
        self.onBack = onBack
    }

    var body: some View {
        HStack {
            LegacyBackButton {
                onBack()
            }

            if let title {
                Spacer()

                Text(title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                    .tracking(titleTracking ?? 0)

                Spacer()

                if showsTrailingPlaceholder {
                    Color.clear
                        .frame(width: trailingWidth, height: trailingWidth)
                }
            } else {
                Spacer()

                if showsTrailingPlaceholder {
                    Color.clear
                        .frame(width: trailingWidth, height: trailingWidth)
                }
            }
        }
    }
}
