import SwiftUI

struct RecurringBillFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: RecurringBillFormViewModel
    @State private var showsCategoryPicker = false
    @State private var showsAmountEditor = false
    @FocusState private var isNoteFocused: Bool

    private let onSaved: () -> Void

    init(
        recurringRepository: RecurringRepository,
        categoryRepository: CategoryRepository,
        billRepository _: BillRepository,
        existingTask: RecurringTaskRecord? = nil,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: RecurringBillFormViewModel(
            recurringRepository: recurringRepository,
            categoryRepository: categoryRepository,
            existingTask: existingTask
        ))
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    FormActionRow(title: TallyLocalization.text(.categories, locale: LanguageManager.shared.currentLocale)) {
                        showsCategoryPicker = true
                    } content: {
                        HStack(spacing: 10) {
                            if let selected = viewModel.selectedCategory {
                                CategoryTile(
                                    iconName: selected.iconKey,
                                    color: viewModel.selectedCategoryColor,
                                    size: 28,
                                    radius: TallyRadii.sm
                                )
                                Text(selected.name)
                                    .font(TallyType.body(15, weight: .medium))
                                    .foregroundStyle(Color.tallyInk)
                            } else {
                                Text(TallyLocalization.text(.uncategorized, locale: LanguageManager.shared.currentLocale))
                                    .font(TallyType.body(15, weight: .medium))
                                    .foregroundStyle(Color.tallyInkFaint)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.tallyInkFaint)
                        }
                    }

                    FormActionRow(title: TallyLocalization.text(.amount, locale: LanguageManager.shared.currentLocale)) {
                        showsAmountEditor = true
                    } content: {
                        HStack(spacing: 5) {
                            TallyAmountText(
                                cents: viewModel.amountCents,
                                size: 17,
                                weight: .semibold,
                                color: viewModel.amountCents > 0 ? .tallyInk : .tallyInkFaint
                            )
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.tallyInkFaint)
                        }
                    }

                    ruleSection

                    FormDisplayRow(title: TallyLocalization.text("next_trigger", locale: LanguageManager.shared.currentLocale)) {
                        Text(viewModel.nextFireText)
                            .font(TallyType.body(14, weight: .medium))
                            .foregroundStyle(Color.tallyInk)
                    }

                    noteRow
                }
                .padding(.horizontal, TallySpacing.s6)
                .padding(.top, TallySpacing.s5)
                .padding(.bottom, TallySpacing.s7)
            }
            .scrollIndicators(.hidden)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.red.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, TallySpacing.s6)
                    .padding(.bottom, TallySpacing.s3)
            }
        }
        .background(Color.tallySurface.ignoresSafeArea())
        .onAppear {
            viewModel.loadCategories()
        }
        .sheet(isPresented: $showsCategoryPicker) {
            CategoryPickerSheet(
                categories: viewModel.categories,
                selectedCategory: viewModel.selectedCategory,
                selectedType: viewModel.selectedType,
                onSelectType: { viewModel.selectType($0) },
                onSelect: { category in
                    viewModel.selectCategory(category)
                    showsCategoryPicker = false
                },
                onAddCategory: {}
            )
            .presentationDetents([.fraction(QuickEntryLayout.categoryPickerDetent)])
            .presentationCornerRadius(QuickEntryLayout.sheetCornerRadius)
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.tallySurface)
        }
        .sheet(isPresented: $showsAmountEditor) {
            RecurringAmountEditorSheet(amountText: $viewModel.amountText) {
                showsAmountEditor = false
            }
            .presentationDetents([.height(240)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(TallyRadii.xl)
            .presentationBackground(Color.tallySurface)
        }
    }

    private var header: some View {
        HStack {
            Button(TallyLocalization.text(.cancel, locale: LanguageManager.shared.currentLocale)) {
                dismiss()
            }
            .font(TallyType.body(14, weight: .medium))
            .foregroundStyle(Color.tallyInkDim)

            Spacer()

            Text(TallyLocalization.text(viewModel.isEditing ? .recurring : .newRecurring, locale: LanguageManager.shared.currentLocale))
                .font(TallyType.display(16, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Button(TallyLocalization.text(.done, locale: LanguageManager.shared.currentLocale)) {
                if viewModel.save() {
                    dismiss()
                    onSaved()
                }
            }
            .font(TallyType.body(14, weight: .semibold))
            .foregroundStyle(viewModel.isValid ? Color.tallyAccent : Color.tallyInkFaint)
            .disabled(!viewModel.isValid)
        }
        .padding(.horizontal, TallySpacing.s5)
        .padding(.top, TallySpacing.s3)
        .padding(.bottom, TallySpacing.s2)
    }

    private var ruleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(TallyLocalization.text(.recurringRule, locale: LanguageManager.shared.currentLocale))
                .font(TallyType.body(12, weight: .medium))
                .foregroundStyle(Color.tallyInkDim)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(RuleOption.allCases) { option in
                    let active = option.rule == viewModel.repeatRule
                    Button {
                        withAnimation(.tallyFast) {
                            viewModel.selectRepeatRule(option.rule)
                        }
                    } label: {
                        Text(option.title)
                            .font(TallyType.body(13, weight: .medium))
                            .foregroundStyle(active ? Color.tallyAccent : Color.tallyInkDim)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 12)
                            .background(active ? Color.tallyAccentTint : Color.tallySurface2)
                            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous)
                                    .stroke(active ? Color.tallyAccent : Color.clear, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, TallySpacing.s4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.tallyLine)
                .frame(height: 0.5)
        }
    }

    private var noteRow: some View {
        HStack(alignment: .center, spacing: TallySpacing.s4) {
            Text(TallyLocalization.text(.note, locale: LanguageManager.shared.currentLocale))
                .font(TallyType.body(13, weight: .medium))
                .foregroundStyle(Color.tallyInkDim)

            TextField(TallyLocalization.text("optional", locale: LanguageManager.shared.currentLocale), text: $viewModel.note)
                .focused($isNoteFocused)
                .font(TallyType.body(14, weight: .regular))
                .foregroundStyle(Color.tallyInk)
                .multilineTextAlignment(.trailing)
                .onChange(of: viewModel.note) { _, newValue in
                    if newValue.count > viewModel.noteLimit {
                        viewModel.note = String(newValue.prefix(viewModel.noteLimit))
                    }
                }
        }
        .padding(.vertical, TallySpacing.s4)
    }
}

private enum RuleOption: CaseIterable, Identifiable {
    case daily
    case weekly
    case monthlyFirst
    case monthlyLast

    var id: RepeatRule { rule }

    var title: String {
        switch self {
        case .daily: return TallyLocalization.text("repeat_daily", locale: LanguageManager.shared.currentLocale)
        case .weekly: return TallyLocalization.text("repeat_weekly", locale: LanguageManager.shared.currentLocale)
        case .monthlyFirst: return TallyLocalization.text("repeat_monthly_first", locale: LanguageManager.shared.currentLocale)
        case .monthlyLast: return TallyLocalization.text("repeat_monthly_last", locale: LanguageManager.shared.currentLocale)
        }
    }

    var rule: RepeatRule {
        switch self {
        case .daily: return .daily
        case .weekly: return .weeklyMonday
        case .monthlyFirst: return .monthlyFirst
        case .monthlyLast: return .monthlyLast
        }
    }
}

private struct FormActionRow<Content: View>: View {
    let title: String
    let action: () -> Void
    let content: Content

    init(title: String, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: TallySpacing.s4) {
                Text(title)
                    .font(TallyType.body(13, weight: .medium))
                    .foregroundStyle(Color.tallyInkDim)

                Spacer(minLength: TallySpacing.s4)

                content
            }
            .padding(.vertical, TallySpacing.s4)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.tallyLine)
                    .frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct FormDisplayRow<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: TallySpacing.s4) {
            Text(title)
                .font(TallyType.body(13, weight: .medium))
                .foregroundStyle(Color.tallyInkDim)

            Spacer(minLength: TallySpacing.s4)

            content
        }
        .padding(.vertical, TallySpacing.s4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.tallyLine)
                .frame(height: 0.5)
        }
    }
}

private struct RecurringAmountEditorSheet: View {
    @Binding var amountText: String
    let onDone: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: TallySpacing.s5) {
            HStack {
                Text(TallyLocalization.text(.amount, locale: LanguageManager.shared.currentLocale))
                    .font(TallyType.display(16, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                Spacer()
                Button(TallyLocalization.text(.done, locale: LanguageManager.shared.currentLocale), action: onDone)
                    .font(TallyType.body(14, weight: .semibold))
                    .foregroundStyle(Color.tallyAccent)
            }

            TextField("0.00", text: $amountText)
                .keyboardType(.decimalPad)
                .focused($focused)
                .font(TallyType.num(32, weight: .semibold))
                .foregroundStyle(Color.tallyInk)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, TallySpacing.s4)
                .padding(.vertical, TallySpacing.s3)
                .background(Color.tallySurface2)
                .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
                .onChange(of: amountText) { _, newValue in
                    amountText = Self.sanitizedAmount(newValue)
                }
        }
        .padding(TallySpacing.s6)
        .background(Color.tallySurface.ignoresSafeArea())
        .onAppear { focused = true }
    }

    private static func sanitizedAmount(_ input: String) -> String {
        let filtered = input.filter { "0123456789.".contains($0) }
        let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return String(parts.prefix(2).joined(separator: ".")) }
        if parts.count == 2 {
            return String(parts[0]) + "." + String(parts[1].prefix(2))
        }
        return filtered
    }
}
