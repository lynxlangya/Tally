import SwiftUI

/// 键盘正上方的横向快捷分类行。左侧是可横滑的高频分类（复用 `QuickEntryCategoryItem`），
/// 右侧固定一个「更多」按钮通往全量 `CategoryPickerSheet`。
/// 选中项变化时自动滚动到可见，避免「选了却看不到选中」。
struct QuickEntrySuggestionRow: View {
    let categories: [CategoryRecord]
    let selectedCategoryID: UUID?
    let onSelect: (CategoryRecord) -> Void
    let onMore: () -> Void

    var body: some View {
        HStack(spacing: QuickEntryLayout.suggestionRowSpacing) {
            scrollingCategories
            moreButton
        }
        .padding(.horizontal, QuickEntryLayout.suggestionRowHorizontalPadding)
        .padding(.vertical, QuickEntryLayout.suggestionRowVerticalPadding)
    }

    private var scrollingCategories: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: QuickEntryLayout.suggestionRowSpacing) {
                    ForEach(categories) { category in
                        QuickEntryCategoryItem(
                            category: category,
                            color: color(for: category),
                            isSelected: category.id == selectedCategoryID,
                            onTap: { onSelect(category) }
                        )
                        .id(category.id)
                    }
                }
                .padding(.trailing, QuickEntryLayout.suggestionEdgeFadeWidth)
            }
            .mask(edgeFadeMask)
            .onChange(of: selectedCategoryID) { _, newValue in
                guard let newValue else { return }
                withAnimation(.tallyBase) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    /// 右缘渐隐：暗示右侧还有可横滑的内容（横向方案唯一的可发现性风险点）。
    private var edgeFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.86),
                .init(color: .clear, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var moreButton: some View {
        Button(action: onMore) {
            VStack(spacing: TallySpacing.s1) {
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .fill(Color.tallySurface2)
                    .frame(
                        width: QuickEntryLayout.suggestionRowTileSize,
                        height: QuickEntryLayout.suggestionRowTileSize
                    )
                    .overlay(
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.tallyInkDim)
                    )
                    // 与带选中环的 QuickEntryCategoryItem 保持等量内边距，tile 顶边对齐。
                    .padding(QuickEntryLayout.suggestionSelectionRingClearance)

                Text(TallyLocalization.text(.more, locale: LanguageManager.shared.currentLocale))
                    .font(TallyType.body(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkDim)
                    .lineLimit(1)
            }
            .frame(width: QuickEntryLayout.suggestionRowTileSize + TallySpacing.s4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quickEntry.suggestion.more")
    }

    private func color(for category: CategoryRecord) -> Color {
        let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }
}
