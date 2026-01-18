import SwiftUI

struct CategoryGridItem: View {
    let category: CategoryRecord
    let color: Color

    var body: some View {
        JOCategoryIconTile(
            iconName: category.iconKey,
            title: category.name,
            iconColor: color
        )
    }
}

struct AddCategoryItem: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: JOSpacing.sm) {
                Circle()
                    .stroke(
                        JOColors.textSecondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(JOColors.textSecondary)
                    )

                Text("添加类别")
                    .font(JOTypography.caption)
                    .foregroundStyle(JOColors.textSecondary)
                    .lineLimit(1)
            }
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
    }
}
