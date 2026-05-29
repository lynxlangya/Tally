import SwiftUI

struct RecurringCategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let selected: CategoryRecord?
    let categoryRepository: CategoryRepository
    let onSelect: (CategoryRecord) -> Void

    @State private var expenseCategories: [CategoryRecord] = []
    @State private var incomeCategories: [CategoryRecord] = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: LegacySpacing.lg) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: LegacySpacing.lg) {
                    section(title: TallyLocalization.text(.expense, locale: LanguageManager.shared.currentLocale), items: expenseCategories)
                    section(title: TallyLocalization.text(.income, locale: LanguageManager.shared.currentLocale), items: incomeCategories)
                }
                .padding(.bottom, LegacySpacing.lg)
            }
        }
        .padding(.horizontal, LegacySpacing.lg)
        .padding(.top, LegacySpacing.lg)
        .background(LegacyColors.background.ignoresSafeArea())
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack {
            LegacyBackButton {
                dismiss()
            }
            Spacer()
            Text(TallyLocalization.text(.categories, locale: LanguageManager.shared.currentLocale))
                .font(LegacyTypography.headline)
                .foregroundStyle(LegacyColors.textPrimary)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func section(title: String, items: [CategoryRecord]) -> some View {
        VStack(alignment: .leading, spacing: LegacySpacing.md) {
            Text(title)
                .font(LegacyTypography.caption)
                .foregroundStyle(LegacyColors.textSecondary)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { category in
                    Button {
                        onSelect(category)
                        dismiss()
                    } label: {
                        CategoryGridItem(
                            category: category,
                            color: color(for: category)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func load() {
        expenseCategories = (try? categoryRepository.list(type: .expense)) ?? []
        incomeCategories = (try? categoryRepository.list(type: .income)) ?? []
    }

    private func color(for category: CategoryRecord) -> Color {
        let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }
}
