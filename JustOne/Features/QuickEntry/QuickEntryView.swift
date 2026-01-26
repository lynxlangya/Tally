import SwiftUI

struct QuickEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: QuickEntryViewModel
    @State private var showsDatePicker = false
    private let selectionOnly: Bool
    private let onCategorySelected: ((CategoryRecord) -> Void)?

    init(
        repository: BillRepository,
        categoryRepository: CategoryRepository,
        editingBill: BillRecord? = nil,
        selectionOnly: Bool = false,
        onCategorySelected: ((CategoryRecord) -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: QuickEntryViewModel(
            repository: repository,
            categoryRepository: categoryRepository,
            editingBill: editingBill
        ))
        self.selectionOnly = selectionOnly
        self.onCategorySelected = onCategorySelected
    }

    var body: some View {
        JOSheetContainer(
            cornerRadius: QuickEntryLayout.sheetCornerRadius,
            background: JOColors.surface.opacity(QuickEntryLayout.sheetBackgroundOpacity),
            borderOpacity: QuickEntryLayout.sheetBorderOpacity
        ) {
            VStack(spacing: 0) {
                JOSheetHandle(
                    width: QuickEntryLayout.handleWidth,
                    height: QuickEntryLayout.handleHeight,
                    opacity: 0.2
                )
                .padding(.top, JOSpacing.md)
                .padding(.bottom, JOSpacing.sm)

                if viewModel.step == .category {
                    categoryContent
                } else {
                    amountContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.bottom, JOSpacing.lg)
        }
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .presentationDetents(detents)
        .presentationDragIndicator(.hidden)
        .joPresentationBackground(JOColors.background)
        .animation(.easeInOut(duration: 0.2), value: viewModel.step)
        .onAppear {
            viewModel.load()
        }
        .sheet(isPresented: $showsDatePicker) {
            JODatePickerSheet(
                mode: .yearMonthDay,
                years: viewModel.availableYears,
                selection: $viewModel.selectedDate,
                title: "选择时间"
            )
            .presentationDetents([.height(QuickEntryLayout.datePickerSheetHeight)])
            .presentationDragIndicator(.hidden)
            .joPresentationBackground(.clear)
        }
    }

    private var detents: Set<PresentationDetent> {
        if viewModel.step == .category {
            return [.fraction(QuickEntryLayout.categoryDetent)]
        }
        return [.fraction(QuickEntryLayout.amountDetent)]
    }

    private var categoryContent: some View {
        VStack(spacing: JOSpacing.lg) {
            HStack {
                Text("选择类别")
                    .font(JOTypography.headline)
                    .foregroundStyle(JOColors.textSecondary)
                    .tracking(2)

                Spacer()

                JOBillTypeSegmentedControl(selection: $viewModel.selectedType)
            }
            .padding(.horizontal, QuickEntryLayout.headerHorizontalPadding)
            .padding(.bottom, JOSpacing.sm)

            ScrollView {
                LazyVGrid(columns: categoryColumns, spacing: QuickEntryLayout.categoryGridSpacingY) {
                    ForEach(viewModel.categories) { category in
                        Button {
                            if selectionOnly {
                                onCategorySelected?(category)
                                dismiss()
                            } else {
                                viewModel.selectCategory(category)
                            }
                        } label: {
                            QuickEntryCategoryItem(
                                category: category,
                                color: categoryColor(for: category)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, JOSpacing.lg)
                .padding(.bottom, JOSpacing.xl)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var amountContent: some View {
        GeometryReader { proxy in
            amountContentBody(containerWidth: proxy.size.width)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func amountContentBody(containerWidth: CGFloat) -> some View {
        let availableWidth = max(containerWidth - QuickEntryLayout.headerHorizontalPadding * 2, 0)

        return VStack(spacing: JOSpacing.lg) {
            VStack(spacing: JOSpacing.lg) {
                if let category = viewModel.selectedCategory {
                    Circle()
                        .fill(JOColors.surface)
                        .frame(width: QuickEntryLayout.amountIconSize, height: QuickEntryLayout.amountIconSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: category.iconKey)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(categoryColor(for: category))
                        )
                        .onTapGesture {
                            viewModel.resetToCategory()
                        }
                }

                QuickEntryNoteRow(
                    title: viewModel.selectedCategory?.name ?? "",
                    note: $viewModel.note
                )
                .frame(width: availableWidth * QuickEntryLayout.noteWidthRatio)

                amountDisplay
            }
            .padding(.top, JOSpacing.lg)
            .padding(.bottom, JOSpacing.sm)
            .padding(.horizontal, QuickEntryLayout.headerHorizontalPadding)

            VStack(spacing: JOSpacing.lg) {
                QuickEntryKeypad { key in
                    switch key {
                    case .calendar:
                        showsDatePicker = true
                    case .add:
                        viewModel.handleKey(key)
                    default:
                        viewModel.handleKey(key)
                    }
                }

                Button(action: handleSave) {
                    HStack(spacing: JOSpacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                        Text("确认记账")
                            .font(JOTypography.headline)
                    }
                    .frame(maxWidth: .infinity, minHeight: QuickEntryLayout.confirmButtonHeight)
                    .foregroundStyle(JOColors.accentForeground)
                    .background(JOColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(QuickEntryLayout.keypadSectionPadding)
        }
    }

    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: JOSpacing.xs) {
            Text("¥")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.4))

            Text(viewModel.displayAmountText)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(JOColors.textPrimary)

            BlinkingCursor()
        }
    }

    private var categoryColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: QuickEntryLayout.categoryGridSpacingX),
            count: QuickEntryLayout.categoryGridColumns
        )
    }

    private func categoryColor(for category: CategoryRecord) -> Color {
        let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }

    private func handleSave() {
        if viewModel.save() {
            dismiss()
        }
    }
}

private struct QuickEntryNoteRow: View {
    let title: String
    @Binding var note: String

    var body: some View {
        HStack(spacing: JOSpacing.sm) {
            Text(title)
                .font(JOTypography.body)
                .foregroundStyle(JOColors.textPrimary)

            Divider()
                .frame(height: 14)
                .background(Color.white.opacity(0.2))

            JOLimitedTextField(
                text: $note,
                placeholder: "添加备注...",
                maxLength: QuickEntryLayout.noteLimit,
                font: .systemFont(ofSize: 14, weight: .regular),
                textColor: UIColor(JOColors.textPrimary),
                placeholderColor: UIColor.white.withAlphaComponent(0.3),
                returnKeyType: .done
            )
        }
        .padding(.horizontal, JOSpacing.lg)
        .frame(height: QuickEntryLayout.amountNoteHeight)
        .background(JOColors.surface.opacity(0.7))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(JOColors.accent)
            .frame(width: 4, height: 48)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}

private extension View {
    @ViewBuilder
    func joPresentationBackground(_ color: Color) -> some View {
        if #available(iOS 16.4, *) {
            presentationBackground(color)
        } else {
            self
        }
    }
}
