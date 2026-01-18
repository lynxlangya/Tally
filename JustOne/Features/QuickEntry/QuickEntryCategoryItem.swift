import SwiftUI

struct QuickEntryCategoryItem: View {
    let category: CategoryRecord
    let color: Color

    var body: some View {
        VStack(spacing: JOSpacing.sm) {
            RoundedRectangle(cornerRadius: QuickEntryLayout.categoryIconCorner, style: .continuous)
                .fill(JOColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: QuickEntryLayout.categoryIconCorner, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .frame(width: QuickEntryLayout.categoryIconSize, height: QuickEntryLayout.categoryIconSize)
                .overlay(
                    Image(systemName: category.iconKey)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(color.opacity(0.95))
                )

            Text(category.name)
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
