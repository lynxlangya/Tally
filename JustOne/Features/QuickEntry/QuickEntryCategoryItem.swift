import SwiftUI

struct QuickEntryCategoryItem: View {
    let category: CategoryRecord
    let color: Color

    var body: some View {
        VStack(spacing: JOSpacing.sm) {
            Circle()
                .fill(JOColors.categoryItemBackground)
                .frame(width: QuickEntryLayout.categoryIconSize, height: QuickEntryLayout.categoryIconSize)
                .overlay(
                    Image(systemName: category.iconKey)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(color)
                        .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 0)
                )

            Text(category.name)
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
