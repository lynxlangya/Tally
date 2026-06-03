import SwiftUI

/// 键盘上方横向快捷行里的单个分类项：图标 tile + 名称，带选中态。
/// 选中时 tile 实心 + 描边环，与 `CategoryPickerSheet` 的全量栅格保持一致的视觉语言。
struct QuickEntryCategoryItem: View {
    let category: CategoryRecord
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: TallySpacing.s1) {
                CategoryTile(
                    iconName: category.iconKey,
                    color: color,
                    size: QuickEntryLayout.suggestionRowTileSize,
                    radius: TallyRadii.lg,
                    filled: isSelected ? .solid : .soft
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
                        .padding(-QuickEntryLayout.suggestionSelectionRingInset)
                )
                // 描边环最外缘 = inset + lineWidth/2，须用 clearance(≥最外缘) 把它纳入 item bounds，
                // 否则会被外层 ScrollView 的 .mask / frame 裁掉顶边（选中态 border 被遮挡）。
                .padding(QuickEntryLayout.suggestionSelectionRingClearance)

                Text(category.name)
                    .font(TallyType.body(11, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.tallyInk : Color.tallyInkDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: QuickEntryLayout.suggestionRowTileSize + TallySpacing.s4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quickEntry.suggestion.\(category.id.uuidString)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
