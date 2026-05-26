import SwiftUI

struct QuickEntryCategoryItem: View {
    let category: CategoryRecord
    let color: Color

    var body: some View {
        JOCategoryIconTile(
            iconName: category.iconKey,
            title: category.name,
            iconColor: color,
            size: QuickEntryLayout.categoryIconSize
        )
        .frame(maxWidth: .infinity)
    }
}
