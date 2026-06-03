import SwiftUI

private extension Color {
    static let quickEntryPickerRing = Color(red: 200 / 255, green: 74 / 255, blue: 56 / 255)
}

struct CategoryPickerSheet: View {
    let categories: [CategoryRecord]
    let frequentCategories: [CategoryRecord]
    let selectedCategory: CategoryRecord?
    let selectedType: BillType?
    let onSelectType: ((BillType) -> Void)?
    let onSelect: (CategoryRecord) -> Void
    let onAddCategory: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: QuickEntryLayout.categoryGridSpacingX),
        count: QuickEntryLayout.categoryGridColumns
    )

    init(
        categories: [CategoryRecord],
        frequentCategories: [CategoryRecord] = [],
        selectedCategory: CategoryRecord?,
        selectedType: BillType? = nil,
        onSelectType: ((BillType) -> Void)? = nil,
        onSelect: @escaping (CategoryRecord) -> Void,
        onAddCategory: @escaping () -> Void
    ) {
        self.categories = categories
        self.frequentCategories = frequentCategories
        self.selectedCategory = selectedCategory
        self.selectedType = selectedType
        self.onSelectType = onSelectType
        self.onSelect = onSelect
        self.onAddCategory = onAddCategory
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            typeToggleIfNeeded

            ScrollView {
                VStack(alignment: .leading, spacing: QuickEntryLayout.pickerSectionSpacing) {
                    frequentSectionIfNeeded
                    allSection
                }
                .padding(.top, TallySpacing.s2)
                .padding(.horizontal, TallySpacing.s4)
                .padding(.bottom, TallySpacing.s6)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.tallySurface.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Text(TallyLocalization.text(.categories, locale: LanguageManager.shared.currentLocale))
                .font(TallyType.body(17, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.tallyInkDim)
                    .frame(width: 32, height: 32)
                    .background(Color.tallySurface2)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, TallySpacing.s5)
        .padding(.top, TallySpacing.s2)
        .padding(.bottom, TallySpacing.s3)
    }

    @ViewBuilder
    private var typeToggleIfNeeded: some View {
        if let selectedType, let onSelectType {
            CategoryPickerTypeToggle(
                selectedType: selectedType,
                onSelect: onSelectType
            )
            .padding(.horizontal, TallySpacing.s5)
            .padding(.bottom, TallySpacing.s4)
        }
    }

    /// 顶部「常用」区：算法高频，动态。冷启动 / selectionOnly 时 `frequentCategories` 为空，整层隐藏。
    @ViewBuilder
    private var frequentSectionIfNeeded: some View {
        if !frequentCategories.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader(.frequentCategories)
                LazyVGrid(columns: columns, spacing: QuickEntryLayout.categoryGridSpacingY) {
                    ForEach(frequentCategories) { category in
                        categoryButton(category)
                    }
                }
            }
        }
    }

    /// 下方「全部」区：永远固定 `sortOrder`，肌肉记忆锚点。
    private var allSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !frequentCategories.isEmpty {
                sectionHeader(.allCategories)
            }
            LazyVGrid(columns: columns, spacing: QuickEntryLayout.categoryGridSpacingY) {
                ForEach(categories) { category in
                    categoryButton(category)
                }
                addCategoryButton
            }
        }
    }

    private func sectionHeader(_ key: L10nKey) -> some View {
        Text(TallyLocalization.text(key, locale: LanguageManager.shared.currentLocale))
            .font(TallyType.body(12, weight: .semibold))
            .foregroundStyle(Color.tallyInkFaint)
            .padding(.leading, TallySpacing.s1)
            .padding(.bottom, QuickEntryLayout.pickerSectionHeaderBottomPadding)
    }

    private func categoryButton(_ category: CategoryRecord) -> some View {
        let active = category.id == selectedCategory?.id
        return Button {
            onSelect(category)
            dismiss()
        } label: {
            VStack(spacing: TallySpacing.s2) {
                CategoryTile(
                    iconName: category.iconKey,
                    color: categoryColor(for: category),
                    size: QuickEntryLayout.pickerTileSize,
                    radius: TallyRadii.lg,
                    filled: active ? .solid : .soft
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous)
                        .stroke(active ? Color.quickEntryPickerRing : Color.clear, lineWidth: 1.5)
                        .padding(-3)
                )

                Text(category.name)
                    .font(TallyType.body(12, weight: active ? .semibold : .medium))
                    .foregroundStyle(active ? Color.tallyInk : Color.tallyInkDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, TallySpacing.s2)
        }
        .buttonStyle(.plain)
    }

    private var addCategoryButton: some View {
        Button {
            onAddCategory()
            dismiss()
        } label: {
            VStack(spacing: TallySpacing.s2) {
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .foregroundStyle(Color.tallyLineHi)
                    .frame(width: QuickEntryLayout.pickerTileSize, height: QuickEntryLayout.pickerTileSize)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Color.tallyInkFaint)
                    )

                Text(TallyLocalization.text(.newCategory, locale: LanguageManager.shared.currentLocale))
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, TallySpacing.s2)
        }
        .buttonStyle(.plain)
    }

    private func categoryColor(for category: CategoryRecord) -> Color {
        let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }
}

private struct CategoryPickerTypeToggle: View {
    let selectedType: BillType
    let onSelect: (BillType) -> Void

    var body: some View {
        HStack(spacing: 2) {
            toggleButton(type: .expense, title: TallyLocalization.text(.expense, locale: LanguageManager.shared.currentLocale))
            toggleButton(type: .income, title: TallyLocalization.text(.income, locale: LanguageManager.shared.currentLocale))
        }
        .padding(3)
        .background(Color.tallySurface2)
        .clipShape(Capsule(style: .continuous))
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func toggleButton(type: BillType, title: String) -> some View {
        let active = selectedType == type
        return Button {
            withAnimation(.tallyBase) {
                onSelect(type)
            }
        } label: {
            Text(title)
                .font(TallyType.body(13, weight: .semibold))
                .tracking(0.65)
                .foregroundStyle(active ? Color.tallyInk : Color.tallyInkFaint)
                .padding(.horizontal, 18)
                .padding(.vertical, 7)
                .background(active ? Color.tallySurface : Color.clear)
                .clipShape(Capsule(style: .continuous))
                .if(active) { view in
                    view.tallyShadow(.shadow1)
                }
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
