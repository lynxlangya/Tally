import SwiftUI

struct RecurringBillFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: RecurringBillFormViewModel
    @State private var showsCategoryPicker = false
    @State private var showsDatePicker = false
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNoteFocused: Bool

    private let onSaved: () -> Void

    init(
        recurringRepository: RecurringRepository,
        categoryRepository: CategoryRepository,
        billRepository: BillRepository,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: RecurringBillFormViewModel(
            recurringRepository: recurringRepository,
            categoryRepository: categoryRepository
        ))
        self.billRepository = billRepository
        self.onSaved = onSaved
    }

    private let billRepository: BillRepository

    var body: some View {
        JOSheetContainer(
            cornerRadius: 28,
            background: JOColors.surface.opacity(0.92),
            borderOpacity: 0.08
        ) {
            VStack(spacing: JOSpacing.lg) {
                header

                VStack(spacing: JOSpacing.md) {
                    formRow(title: "类别") {
                        Button {
                            showsCategoryPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                if let selected = viewModel.selectedCategory {
                                    JOCategoryIconTile(
                                        iconName: selected.iconKey,
                                        title: selected.name,
                                        iconColor: viewModel.selectedCategoryColor,
                                        size: 28,
                                        iconSize: 14,
                                        showsTitle: false
                                    )
                                    Text(selected.name)
                                        .foregroundStyle(JOColors.textPrimary)
                                } else {
                                    Text("请选择")
                                        .foregroundStyle(JOColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(JOColors.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    formRow(title: "首次记账日期") {
                        Button {
                            showsDatePicker = true
                        } label: {
                            HStack {
                                Text(viewModel.firstDateText)
                                    .foregroundStyle(JOColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(JOColors.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    formRow(title: "金额") {
                        TextField("0.00", text: $viewModel.amountText)
                            .keyboardType(.decimalPad)
                            .focused($isAmountFocused)
                            .foregroundStyle(JOColors.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: viewModel.amountText) { _, newValue in
                                viewModel.amountText = viewModel.sanitizedAmount(newValue)
                            }
                    }

                    formRow(title: "备注") {
                        TextField("选填", text: $viewModel.note)
                            .focused($isNoteFocused)
                            .foregroundStyle(JOColors.textPrimary)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: viewModel.note) { _, newValue in
                                if newValue.count > viewModel.noteLimit {
                                    viewModel.note = String(newValue.prefix(viewModel.noteLimit))
                                }
                            }
                    }

                    formRow(title: "重复") {
                        Menu {
                            ForEach(RepeatRule.allCases) { rule in
                                Button(rule.title) {
                                    viewModel.repeatRule = rule
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.repeatRule.title)
                                    .foregroundStyle(JOColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(JOColors.textSecondary)
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(JOTypography.caption)
                        .foregroundStyle(Color.red.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                JOPrimaryButton("保存", isEnabled: viewModel.isValid) {
                    if viewModel.save() {
                        dismiss()
                        onSaved()
                    }
                }
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.vertical, JOSpacing.lg)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.black.opacity(0.35).ignoresSafeArea())
        .sheet(isPresented: $showsCategoryPicker) {
            QuickEntryView(
                repository: billRepository,
                categoryRepository: viewModel.categoryRepository,
                selectionOnly: true
            ) { category in
                viewModel.selectCategory(category)
                showsCategoryPicker = false
            }
        }
        .sheet(isPresented: $showsDatePicker) {
            DatePickerSheet(date: $viewModel.firstDate) {
                showsDatePicker = false
            }
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .font(JOTypography.body)
            .foregroundStyle(JOColors.textSecondary)

            Spacer()

            Text("新增定时记账")
                .font(JOTypography.headline)
                .foregroundStyle(JOColors.textPrimary)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private func formRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: JOSpacing.md) {
            Text(title)
                .font(JOTypography.body)
                .foregroundStyle(JOColors.textSecondary)
            Spacer()
            content()
        }
        .padding(.horizontal, JOSpacing.md)
        .padding(.vertical, JOSpacing.sm)
        .background(JOColors.profileRowBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(JOColors.cardBorder, lineWidth: 1)
        )
    }
}

private struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            DatePicker(
                "首次记账日期",
                selection: $date,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(JOColors.accent)
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .colorScheme(.dark)

            JOPrimaryButton("完成") {
                dismiss()
                onDone()
            }
        }
        .padding(JOSpacing.lg)
        .background(JOColors.background.ignoresSafeArea())
    }
}
