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
        VStack(spacing: JOSpacing.lg) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: JOSpacing.lg) {
                    section(title: "支出", items: expenseCategories)
                    section(title: "收入", items: incomeCategories)
                }
                .padding(.bottom, JOSpacing.lg)
            }
        }
        .padding(.horizontal, JOSpacing.lg)
        .padding(.top, JOSpacing.lg)
        .background(JOColors.background.ignoresSafeArea())
        .onAppear(perform: load)
    }

    private var header: some View {
        HStack {
            JOBackButton {
                dismiss()
            }
            Spacer()
            Text("选择类别")
                .font(JOTypography.headline)
                .foregroundStyle(JOColors.textPrimary)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func section(title: String, items: [CategoryRecord]) -> some View {
        VStack(alignment: .leading, spacing: JOSpacing.md) {
            Text(title)
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)

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
