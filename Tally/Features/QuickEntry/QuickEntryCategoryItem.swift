import SwiftUI

struct QuickEntryCategoryItem: View {
    let category: CategoryRecord
    let color: Color

    var body: some View {
        VStack(spacing: TallySpacing.s2) {
            CategoryTile(
                iconName: category.iconKey,
                color: color,
                size: QuickEntryLayout.pickerTileSize,
                radius: TallyRadii.lg
            )

            Text(category.name)
                .font(TallyType.body(12, weight: .medium))
                .foregroundStyle(Color.tallyInkDim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
