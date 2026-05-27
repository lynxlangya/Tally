import SwiftUI

private extension Color {
    static let quickEntryPickerRing = Color(red: 200 / 255, green: 74 / 255, blue: 56 / 255)
}

struct CategoryPickerSheet: View {
    let categories: [CategoryRecord]
    let selectedCategory: CategoryRecord?
    let onSelect: (CategoryRecord) -> Void
    let onAddCategory: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: QuickEntryLayout.categoryGridSpacingX),
        count: QuickEntryLayout.categoryGridColumns
    )

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                LazyVGrid(columns: columns, spacing: QuickEntryLayout.categoryGridSpacingY) {
                    ForEach(categories) { category in
                        categoryButton(category)
                    }

                    addCategoryButton
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
            Text("选择分类")
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

                Text("新分类")
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
