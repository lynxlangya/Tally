import SwiftUI

struct CategoryGridItem: View {
    let category: CategoryRecord
    let color: Color

    var body: some View {
        VStack(spacing: JOSpacing.sm) {
            ZStack {
                Circle()
                    .fill(JOColors.categoryItemBackground)
                    .frame(width: 56, height: 56)

                Image(systemName: category.iconKey)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 0)
            }

            Text(category.name)
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)
                .lineLimit(1)
        }
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
