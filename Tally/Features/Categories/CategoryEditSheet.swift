import SwiftUI

struct CategoryEditSheet: View {
    let type: BillType
    let existing: CategoryRecord?
    let onSave: (String, String, UInt32) -> String?
    let onDelete: (CategoryRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColorHex: UInt32
    @State private var saveErrorMessage: String?

    private enum Constants {
        static let nameLimit = 8
        static let previewSize: CGFloat = 86
        static let previewRadius: CGFloat = 24
        static let gridSpacing: CGFloat = 10
    }

    init(
        type: BillType,
        existing: CategoryRecord?,
        onSave: @escaping (String, String, UInt32) -> String?,
        onDelete: @escaping (CategoryRecord) -> Void
    ) {
        self.type = type
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete

        let defaultIcon = CategoryIconCatalog.icons.first ?? "tag"
        let initialIcon = existing?.iconKey ?? defaultIcon
        _selectedIcon = State(initialValue: initialIcon)
        _name = State(initialValue: existing?.name ?? "")

        let fallbackHex = existing.map { CategoryColorPalette.defaultHex(for: $0.id) }
            ?? (CategoryColorPalette.hexValues.first ?? 0xB8553E)
        let storedHex = existing?.colorHex.flatMap { UInt32($0) } ?? fallbackHex
        _selectedColorHex = State(initialValue: storedHex)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: TallySpacing.s6) {
                    previewSection
                    if let saveErrorMessage {
                        ErrorBanner(message: saveErrorMessage)
                    }
                    colorSection
                    iconSection

                    if let existing, !existing.isSystem {
                        deleteButton(for: existing)
                            .padding(.top, TallySpacing.s2)
                    }
                }
                .padding(.horizontal, TallySpacing.s6)
                .padding(.top, TallySpacing.s4)
                .padding(.bottom, TallySpacing.s8)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.tallySurface)
        .onChange(of: name) { _, _ in
            saveErrorMessage = nil
        }
        .onChange(of: selectedIcon) { _, _ in
            saveErrorMessage = nil
        }
        .onChange(of: selectedColorHex) { _, _ in
            saveErrorMessage = nil
        }
    }

    private var header: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .font(TallyType.body(14, weight: .medium))
            .foregroundStyle(Color.tallyInkDim)
            .buttonStyle(.plain)

            Spacer()

            Text(existing == nil ? "新分类" : "编辑分类")
                .font(TallyType.display(18, weight: .semibold))
                .foregroundStyle(Color.tallyInk)

            Spacer()

            Button("完成") {
                saveAndDismiss()
            }
            .font(TallyType.body(14, weight: .semibold))
            .foregroundStyle(canFinish ? Color.tallyAccent : Color.tallyInkFaint)
            .buttonStyle(.plain)
            .disabled(!canFinish)
        }
        .padding(.horizontal, TallySpacing.s5)
        .padding(.top, TallySpacing.s1)
        .padding(.bottom, TallySpacing.s2)
    }

    private var previewSection: some View {
        VStack(spacing: TallySpacing.s4) {
            CategoryTile(
                iconName: selectedIcon,
                color: selectedColor,
                size: Constants.previewSize,
                radius: Constants.previewRadius,
                filled: .solid
            )

            TextField("分类名称", text: $name)
                .font(TallyType.display(22, weight: .semibold))
                .foregroundStyle(Color.tallyInk)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .onChange(of: name) { _, newValue in
                    if newValue.count > Constants.nameLimit {
                        name = String(newValue.prefix(Constants.nameLimit))
                    }
                }
                .padding(.horizontal, TallySpacing.s3)
                .padding(.vertical, TallySpacing.s2)
                .frame(width: 220)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.tallyLineHi)
                        .frame(height: 0.5)
                }
                .disabled(isReadOnly)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, TallySpacing.s2)
        .padding(.bottom, TallySpacing.s2)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s3) {
            Eyebrow("颜色")

            LazyVGrid(columns: colorColumns, spacing: Constants.gridSpacing) {
                ForEach(CategoryColorPalette.hexValues.indices, id: \.self) { index in
                    let color = Color(hex: CategoryColorPalette.hexValues[index])
                    ColorSwatch(
                        color: color,
                        isSelected: selectedColorHex == CategoryColorPalette.hexValues[index],
                        isEnabled: !isReadOnly
                    ) {
                        selectedColorHex = CategoryColorPalette.hexValues[index]
                    }
                }
            }
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s3) {
            Eyebrow("图标")

            LazyVGrid(columns: iconColumns, spacing: Constants.gridSpacing) {
                ForEach(CategoryIconCatalog.sheetIcons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        IconSwatch(icon: icon, isSelected: selectedIcon == icon)
                    }
                    .buttonStyle(.plain)
                    .disabled(isReadOnly)
                    .accessibilityLabel(icon)
                }
            }
        }
    }

    private func deleteButton(for record: CategoryRecord) -> some View {
        Button(role: .destructive) {
            dismiss()
            onDelete(record)
        } label: {
            Label("删除分类", systemImage: "trash")
                .font(TallyType.body(14, weight: .semibold))
                .foregroundStyle(Color.red.opacity(0.88))
                .frame(maxWidth: .infinity)
                .padding(.vertical, TallySpacing.s3)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var selectedColor: Color {
        Color(hex: selectedColorHex)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canFinish: Bool {
        isReadOnly || canSave
    }

    private var isReadOnly: Bool {
        existing?.isSystem == true
    }

    private var colorColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Constants.gridSpacing), count: 6)
    }

    private var iconColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: 6)
    }

    private func saveAndDismiss() {
        if isReadOnly {
            dismiss()
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !hasChanges {
            dismiss()
            return
        }
        if let errorMessage = onSave(trimmed, selectedIcon, selectedColorHex) {
            saveErrorMessage = errorMessage
        } else {
            dismiss()
        }
    }

    private var hasChanges: Bool {
        guard let existing else { return true }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingHex = existing.colorHex.flatMap { UInt32($0) }
            ?? CategoryColorPalette.defaultHex(for: existing.id)
        return trimmed != existing.name
            || selectedIcon != existing.iconKey
            || selectedColorHex != existingHex
    }
}

private struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: Constants.swatchRadius + 4, style: .continuous)
                        .stroke(color, lineWidth: 4)
                    RoundedRectangle(cornerRadius: Constants.swatchRadius + 2, style: .continuous)
                        .stroke(Color.tallyBg, lineWidth: 2)
                }

                RoundedRectangle(cornerRadius: Constants.swatchRadius, style: .continuous)
                    .fill(color)
                    .padding(isSelected ? 5 : 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.swatchRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                            .padding(isSelected ? 5 : 0)
                    )
            }
            .aspectRatio(1, contentMode: .fit)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.tallyFast, value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private enum Constants {
        static let swatchRadius: CGFloat = 14
    }
}

private struct IconSwatch: View {
    let icon: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous)
                .fill(isSelected ? Color.tallyAccentTint : Color.tallySurface2)
                .overlay(
                    RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous)
                        .stroke(isSelected ? Color.tallyAccent : Color.clear, lineWidth: 1.5)
                )

            TallyIcon(name: icon, size: 22)
                .foregroundStyle(isSelected ? Color.tallyAccent : Color.tallyInkDim)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.tallyFast, value: isSelected)
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: TallySpacing.s2) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))

            Text(message)
                .font(TallyType.body(12, weight: .semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.red.opacity(0.88))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TallySpacing.s3)
        .padding(.vertical, TallySpacing.s2)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous))
    }
}
