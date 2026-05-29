import SwiftUI

struct CategoryGridItem: View {
    let category: CategoryRecord
    let color: Color?
    var usageCount: Int?

    init(category: CategoryRecord, color: Color? = nil, usageCount: Int? = nil) {
        self.category = category
        self.color = color
        self.usageCount = usageCount
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                CategoryTile(
                    iconName: category.iconKey,
                    color: categoryColor,
                    size: 56,
                    radius: TallyRadii.lg
                )

                if let usageCount {
                    Text("\(usageCount)")
                        .font(TallyType.num(10, weight: .semibold))
                        .foregroundStyle(Color.tallyInkDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(minWidth: 18, minHeight: 18)
                        .padding(.horizontal, 4)
                        .background(Color.tallyBg)
                        .clipShape(Capsule(style: .continuous))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.tallyLineHi, lineWidth: 0.5)
                        )
                        .offset(x: 4, y: -4)
                }
            }

            Text(category.name)
                .font(TallyType.body(12, weight: .medium))
                .foregroundStyle(Color.tallyInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, TallySpacing.s1)
        .padding(.vertical, TallySpacing.s3)
        .contentShape(Rectangle())
    }

    private var categoryColor: Color {
        if let color {
            return color
        }
        let hex = category.colorHex.map { UInt32($0) }
            ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }
}

struct AddCategoryItem: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                    .stroke(
                        Color.tallyLineHi,
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.tallyInkFaint)
                    )

                Text(TallyLocalization.text(.newCategory, locale: LanguageManager.shared.currentLocale))
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, TallySpacing.s1)
            .padding(.vertical, TallySpacing.s3)
            .opacity(isDisabled ? 0.42 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
