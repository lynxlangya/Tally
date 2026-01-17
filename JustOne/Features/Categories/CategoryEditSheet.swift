import SwiftUI

struct CategoryEditSheet: View {
    let type: BillType
    let existing: CategoryRecord?
    let onSave: (String, String, UInt32) -> Void
    let onDelete: (CategoryRecord) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColorIndex: Int
    @State private var randomColorHex: UInt32
    @State private var usesRandomColor: Bool
    @FocusState private var isNameFocused: Bool

    private enum Constants {
        static let nameLimit = 5
        static let previewSize: CGFloat = 120
        static let previewIconSize: CGFloat = 42
        static let fieldCornerRadius: CGFloat = 18
        static let colorSwatchSize: CGFloat = 37
        static let colorSwatchSpacing: CGFloat = 12
        static let colorGridColumns: Int = 8
        static let iconCellSize: CGFloat = 48
        static let iconRowCount = 3
        static let iconSpacing: CGFloat = 12
        static let sectionTitleOpacity: CGFloat = 0.45
    }

    init(
        type: BillType,
        existing: CategoryRecord?,
        onSave: @escaping (String, String, UInt32) -> Void,
        onDelete: @escaping (CategoryRecord) -> Void
    ) {
        self.type = type
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete

        let defaultIcon = CategoryIconCatalog.icons.first ?? "questionmark"
        let initialIcon = existing?.iconKey ?? defaultIcon
        _selectedIcon = State(initialValue: initialIcon)
        _name = State(initialValue: existing?.name ?? "")

        let fallbackHex = existing.map { CategoryColorPalette.defaultHex(for: $0.id) }
            ?? (CategoryColorPalette.hexValues.first ?? 0x13EC37)
        let storedHex = existing?.colorHex.flatMap { UInt32($0) } ?? fallbackHex
        if let index = CategoryColorPalette.hexValues.firstIndex(of: storedHex) {
            _selectedColorIndex = State(initialValue: index)
            _usesRandomColor = State(initialValue: false)
            _randomColorHex = State(initialValue: CategoryColorPalette.randomHex())
        } else {
            _selectedColorIndex = State(initialValue: 0)
            _usesRandomColor = State(initialValue: true)
            _randomColorHex = State(initialValue: storedHex)
        }
    }

    private var selectedColorHex: UInt32 {
        if usesRandomColor {
            return randomColorHex
        }
        let palette = CategoryColorPalette.hexValues
        guard palette.indices.contains(selectedColorIndex) else {
            return palette.first ?? 0x13EC37
        }
        return palette[selectedColorIndex]
    }

    private var selectedColor: Color {
        Color(hex: selectedColorHex)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: JOSpacing.lg) {
                ScrollView {
                    VStack(alignment: .leading, spacing: JOSpacing.xl) {
                        previewSection
                        VStack(alignment: .leading, spacing: JOSpacing.xl) {
                            nameSection
                            colorSection
                            iconSection
                        }
                        .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, JOSpacing.xl)
                }
                .scrollIndicators(.hidden)

                actionBar
                    .padding(.top, 5)
                    .padding(.bottom, proxy.safeAreaInsets.bottom)
            }
            .padding(.horizontal, JOSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(JOColors.background.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        if let existing {
            HStack(spacing: JOSpacing.md) {
                deleteButton(for: existing)
                    .frame(maxWidth: .infinity)
                saveButton
                    .frame(maxWidth: .infinity)
            }
        } else {
            saveButton
        }
    }

    private var previewSection: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(selectedColor)
                    .frame(width: Constants.previewSize, height: Constants.previewSize)
                    .shadow(color: selectedColor.opacity(0.35), radius: 18, x: 0, y: 8)
                    .shadow(color: selectedColor.opacity(0.2), radius: 8, x: 0, y: 4)

                Image(systemName: selectedIcon)
                    .font(.system(size: Constants.previewIconSize, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.sm) {
            Text("名称")
                .font(JOTypography.caption)
                .foregroundStyle(Color.white.opacity(Constants.sectionTitleOpacity))
                .tracking(2)

            HStack {
                TextField(
                    text: $name,
                    prompt: Text("最多 5 个字")
                        .foregroundStyle(Color.white.opacity(0.4))
                ) {
                    EmptyView()
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(JOColors.textPrimary)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onChange(of: name) { _, newValue in
                    if newValue.count > Constants.nameLimit {
                        name = String(newValue.prefix(Constants.nameLimit))
                    }
                }

                if !name.isEmpty {
                    Button {
                        name = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, JOSpacing.md)
            .padding(.horizontal, JOSpacing.lg)
            .background(JOColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Constants.fieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.fieldCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.md) {
            Text("颜色")
                .font(JOTypography.caption)
                .foregroundStyle(Color.white.opacity(Constants.sectionTitleOpacity))
                .tracking(2)

            LazyVGrid(columns: colorColumns, spacing: JOSpacing.md) {
                ForEach(CategoryColorPalette.hexValues.indices, id: \.self) { index in
                    let color = Color(hex: CategoryColorPalette.hexValues[index])
                    ColorSwatch(
                        color: color,
                        isSelected: !usesRandomColor && selectedColorIndex == index,
                        size: Constants.colorSwatchSize
                    ) {
                        usesRandomColor = false
                        selectedColorIndex = index
                    }
                }

                RandomColorSwatch(
                    color: Color(hex: randomColorHex),
                    isSelected: usesRandomColor,
                    size: Constants.colorSwatchSize
                ) {
                    randomColorHex = CategoryColorPalette.randomHex()
                    usesRandomColor = true
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.md) {
            Text("图标")
                .font(JOTypography.caption)
                .foregroundStyle(Color.white.opacity(Constants.sectionTitleOpacity))
                .tracking(2)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: iconRows, spacing: Constants.iconSpacing) {
                    ForEach(CategoryIconCatalog.icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            IconSwatch(
                                icon: icon,
                                isSelected: selectedIcon == icon,
                                size: Constants.iconCellSize
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: iconGridHeight)
                .padding(.vertical, 2)
            }
            .padding(.vertical, 4)
        }
    }

    private var saveButton: some View {
        Button {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            onSave(trimmed, selectedIcon, selectedColorHex)
            dismiss()
        } label: {
            HStack(spacing: JOSpacing.sm) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                Text("保存")
                    .font(JOTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, JOSpacing.md)
        }
        .buttonStyle(JOPrimaryButtonStyle(isEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func deleteButton(for record: CategoryRecord) -> some View {
        Button {
            dismiss()
            onDelete(record)
        } label: {
            HStack(spacing: JOSpacing.sm) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                Text("删除")
                    .font(JOTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, JOSpacing.md)
        }
        .buttonStyle(JODestructiveButtonStyle())
    }

    private var colorColumns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(Constants.colorSwatchSize), spacing: Constants.colorSwatchSpacing),
            count: Constants.colorGridColumns
        )
    }

    private var iconRows: [GridItem] {
        Array(
            repeating: GridItem(.fixed(Constants.iconCellSize), spacing: Constants.iconSpacing),
            count: Constants.iconRowCount
        )
    }

    private var iconGridHeight: CGFloat {
        Constants.iconCellSize * CGFloat(Constants.iconRowCount)
            + Constants.iconSpacing * CGFloat(Constants.iconRowCount - 1)
    }
}

struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                if isSelected {
                    Circle()
                        .strokeBorder(JOColors.background, lineWidth: 4)
                        .frame(width: size, height: size)
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: size, height: size)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct RandomColorSwatch: View {
    let color: Color
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            .frame(width: size, height: size)
                    )
                Image(systemName: "shuffle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .overlay(
                Group {
                    if isSelected {
                        Circle()
                            .strokeBorder(JOColors.background, lineWidth: 4)
                            .frame(width: size, height: size)
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: size, height: size)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

struct IconSwatch: View {
    let icon: String
    let isSelected: Bool
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(JOColors.surface)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? Color.white.opacity(0.95) : Color.clear, lineWidth: 2)
            )
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.95) : Color.white.opacity(0.4))
            )
    }
}
