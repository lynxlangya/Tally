import SwiftUI
import UIKit

struct QuickEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: QuickEntryViewModel
    @State private var showsCategoryPicker = false
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
        Group {
            if selectionOnly {
                selectionContent
            } else {
                mainContent
            }
        }
            .presentationDetents([.fraction(selectionOnly ? QuickEntryLayout.categoryPickerDetent : QuickEntryLayout.sheetDetent)])
            .presentationCornerRadius(QuickEntryLayout.sheetCornerRadius)
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color.tallySurface)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                viewModel.load()
            }
            .tallySheet(isPresented: $showsCategoryPicker, heightFraction: QuickEntryLayout.categoryPickerDetent) {
                CategoryPickerSheet(
                    categories: viewModel.categories,
                    selectedCategory: viewModel.selectedCategory,
                    selectedType: nil,
                    onSelectType: nil,
                    onSelect: handleCategorySelection,
                    onAddCategory: {}
                )
            }
            .sheet(isPresented: $showsDatePicker) {
                QuickEntryDatePickerSheet(selection: $viewModel.selectedDate)
                    .presentationDetents([.height(QuickEntryLayout.datePickerSheetHeight)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(Color.tallySurface)
            }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(Color.tallyLineHi)
                .frame(width: 36, height: 4)
                .padding(.top, TallySpacing.s2)
                .padding(.bottom, TallySpacing.s2)

            header

            VStack(spacing: TallySpacing.s5) {
                categoryChip
                    .padding(.top, TallySpacing.s5)

                Spacer(minLength: TallySpacing.s2)

                HeroAmount(
                    text: viewModel.displayAmount,
                    type: viewModel.selectedType
                )

                dateAndNoteRow

                Spacer(minLength: TallySpacing.s3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, QuickEntryLayout.contentHorizontalPadding)

            VStack(spacing: TallySpacing.s3) {
                QuickEntryKeypad { key in
                    if key == .calendar {
                        showsDatePicker = true
                    } else {
                        viewModel.handleKey(key)
                    }
                }

                saveButton
            }
            .padding(.horizontal, QuickEntryLayout.keypadHorizontalPadding)
            .padding(.bottom, TallySpacing.s4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tallySurface.ignoresSafeArea())
    }

    private var selectionContent: some View {
        CategoryPickerSheet(
            categories: viewModel.categories,
            selectedCategory: viewModel.selectedCategory,
            selectedType: viewModel.selectedType,
            onSelectType: { viewModel.selectedType = $0 },
            onSelect: handleCategorySelection,
            onAddCategory: {}
        )
        .background(Color.tallySurface.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .font(TallyType.body(14, weight: .regular))
            .foregroundStyle(Color.tallyInkDim)
            .padding(6)
            .buttonStyle(.plain)

            Spacer()

            BillTypeToggle(selection: $viewModel.selectedType)

            Spacer()

            Button {
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.tallyInkDim)
                    .frame(width: 36, height: 36)
                    .background(Color.tallySurface2)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("更多")
        }
        .padding(.horizontal, QuickEntryLayout.headerHorizontalPadding)
        .padding(.top, TallySpacing.s1)
    }

    private var categoryChip: some View {
        Button {
            showsCategoryPicker = true
        } label: {
            HStack(spacing: 10) {
                let category = selectedCategoryForDisplay
                CategoryTile(
                    iconName: category.iconKey,
                    color: categoryColor(for: category),
                    size: 28,
                    radius: TallyRadii.sm
                )

                Text(category.name)
                    .font(TallyType.body(14, weight: .medium))
                    .foregroundStyle(Color.tallyInk)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.tallyInkDim.opacity(0.7))
            }
            .padding(.leading, TallySpacing.s2)
            .padding(.trailing, TallySpacing.s4)
            .padding(.vertical, TallySpacing.s2)
            .background(Color.tallySurface2)
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(QuickEntryChipButtonStyle())
    }

    private var dateAndNoteRow: some View {
        HStack(spacing: TallySpacing.s2) {
            Button {
                showsDatePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .regular))
                    Text(dateText)
                        .font(TallyType.body(12, weight: .medium))
                }
                .foregroundStyle(Color.tallyInkDim)
                .padding(.horizontal, TallySpacing.s3)
                .padding(.vertical, 6)
                .background(Color.tallySurface2)
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)

            TallyNoteField(text: $viewModel.note)
                .frame(width: 132, height: 30)
        }
    }

    private var saveButton: some View {
        Button(action: handleSave) {
            HStack(spacing: 10) {
                TallyMark(
                    size: 18,
                    variant: .one,
                    color: viewModel.canSave ? .tallyAccentInk : .tallyInkFaint,
                    strokeWidth: 2.5
                )

                Text("记一笔")
                    .font(TallyType.body(16, weight: .semibold))
                    .tracking(0.64)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, QuickEntryLayout.confirmButtonVerticalPadding)
            .foregroundStyle(viewModel.canSave ? Color.tallyAccentInk : Color.tallyInkFaint)
            .background(viewModel.canSave ? Color.tallyAccent : Color.tallySurface3)
            .clipShape(RoundedRectangle(cornerRadius: QuickEntryLayout.confirmButtonCornerRadius, style: .continuous))
            .if(viewModel.canSave) { view in
                view.tallyShadow(.shadowFab)
            }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
    }

    private var dateText: String {
        Self.dateFormatter.string(from: viewModel.selectedDate)
    }

    private var selectedCategoryForDisplay: CategoryRecord {
        if let category = viewModel.selectedCategory {
            return category
        }
        return CategoryRecord(
            id: SystemCategoryID.uncategorized(for: viewModel.selectedType),
            type: viewModel.selectedType,
            name: "未分类",
            iconKey: "questionmark",
            colorHex: Int(CategoryColorPalette.defaultHex(for: SystemCategoryID.uncategorized(for: viewModel.selectedType))),
            isSystem: true,
            sortOrder: 0
        )
    }

    private func handleCategorySelection(_ category: CategoryRecord) {
        if selectionOnly {
            onCategorySelected?(category)
            dismiss()
        } else {
            viewModel.selectCategory(category)
        }
    }

    private func handleSave() {
        if viewModel.save() {
            dismiss()
        }
    }

    private func categoryColor(for category: CategoryRecord) -> Color {
        let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

private struct BillTypeToggle: View {
    @Binding var selection: BillType

    var body: some View {
        HStack(spacing: 2) {
            toggleButton(type: .expense, title: "支出")
            toggleButton(type: .income, title: "收入")
        }
        .padding(3)
        .background(Color.tallySurface2)
        .clipShape(Capsule(style: .continuous))
    }

    private func toggleButton(type: BillType, title: String) -> some View {
        let active = selection == type
        return Button {
            withAnimation(.tallyBase) {
                selection = type
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

private struct HeroAmount: View {
    let text: String
    let type: BillType

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(type == .expense ? "−" : "+")
                .font(TallyType.num(fontSize * 0.5, weight: .regular))
                .foregroundStyle(signColor.opacity(0.55))
                .padding(.trailing, fontSize * 0.04)

            Yen(fontSize: fontSize, color: Color.tallyInk.opacity(0.82))

            Text(integerPart)
                .font(TallyType.num(fontSize, weight: .medium))
                .foregroundStyle(Color.tallyInk)

            if let decimalPart {
                Text("." + decimalPart)
                    .font(TallyType.num(fontSize * 0.42, weight: .medium))
                    .foregroundStyle(Color.tallyInkDim.opacity(0.55))
                    .padding(.leading, fontSize * 0.04)
            }

            BlinkingCaret(height: fontSize * 0.66, color: caretColor)
                .padding(.leading, 4)
                .baselineOffset(fontSize * -0.08)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .frame(maxWidth: .infinity)
        .accessibilityLabel((type == .expense ? "支出" : "收入") + text)
    }

    private var signColor: Color {
        type == .income ? .tallyAccent : .tallyInkDim
    }

    private var caretColor: Color {
        type == .income ? .tallyAccent : .tallyInkDim
    }

    private var integerPart: String {
        text.split(separator: ".", omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? "0"
    }

    private var decimalPart: String? {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count > 1 else { return nil }
        return String(parts[1])
    }

    private var fontSize: CGFloat {
        let digits = integerPart.filter(\.isNumber).count
        if digits <= 4 { return 84 }
        if digits <= 6 { return 64 }
        return 52
    }
}

private struct BlinkingCaret: View {
    let height: CGFloat
    let color: Color
    @State private var isVisible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1, style: .continuous)
            .fill(color)
            .frame(width: 2, height: height)
            .opacity(isVisible ? 1 : 0.2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}

private struct TallyNoteField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.returnKeyType = .done
        textField.font = .systemFont(ofSize: 13, weight: .regular)
        textField.backgroundColor = .clear
        textField.textColor = UIColor(Color.tallyInk)
        textField.attributedPlaceholder = NSAttributedString(
            string: "添加备注",
            attributes: [
                .foregroundColor: UIColor(Color.tallyInkFaint),
                .font: UIFont.systemFont(ofSize: 13, weight: .regular)
            ]
        )
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.textColor = UIColor(Color.tallyInk)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: TallyNoteField

        init(_ parent: TallyNoteField) {
            self.parent = parent
        }

        @objc func textDidChange(_ sender: UITextField) {
            let value = sender.text ?? ""
            if sender.markedTextRange != nil {
                parent.text = value
                return
            }
            if value.count <= QuickEntryLayout.noteLimit {
                parent.text = value
                return
            }
            let trimmed = String(value.prefix(QuickEntryLayout.noteLimit))
            sender.text = trimmed
            parent.text = trimmed
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

private struct QuickEntryDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Date

    var body: some View {
        VStack(spacing: TallySpacing.s4) {
            HStack {
                Text("选择时间")
                    .font(TallyType.body(17, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("完成")
                        .font(TallyType.body(14, weight: .semibold))
                        .foregroundStyle(Color.tallyAccent)
                }
                .buttonStyle(.plain)
            }

            DatePicker(
                "选择时间",
                selection: $selection,
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(Color.tallyAccent)
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()
        }
        .padding(.horizontal, TallySpacing.s5)
        .padding(.bottom, TallySpacing.s5)
        .background(Color.tallySurface.ignoresSafeArea())
    }
}

private struct QuickEntryChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.tallyFast, value: configuration.isPressed)
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
