import SwiftUI

private enum EmojiIconToken {
    static let placeholder = "__emoji__"
}

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
    @State private var emojiInput: String
    @State private var showsEmojiHint = false
    @FocusState private var isEmojiFieldFocused: Bool
    private enum Constants {
        static let nameLimit = 5
        static let previewSize: CGFloat = 120
        static let previewIconSize: CGFloat = 42
        static let fieldCornerRadius: CGFloat = 18
        static let colorSwatchSize: CGFloat = 37
        static let colorSwatchSpacing: CGFloat = 12
        static let colorGridColumns: Int = 8
        static let iconCellSize: CGFloat = 44
        static let iconRowCount = 4
        static let iconSpacing: CGFloat = 12
        static let sectionTitleOpacity: CGFloat = 0.45
        static let actionBarBottomOffset: CGFloat = 35
        static let emojiPrefix = "emoji:"
        static let emojiPlaceholderGlyph = "😀"
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
        _emojiInput = State(initialValue: "")

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

    private var isEmojiSelected: Bool {
        selectedIcon.hasPrefix(Constants.emojiPrefix)
    }

    private var previewBackgroundColor: Color {
        isEmojiSelected ? JOColors.categoryItemBackground : selectedColor
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
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
                        .padding(.bottom, Constants.actionBarBottomOffset)
                }
                .padding(.horizontal, JOSpacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(JOColors.background.ignoresSafeArea())
                .ignoresSafeArea(.container, edges: .bottom)
                .ignoresSafeArea(.keyboard, edges: .bottom)

                if showsEmojiHint {
                    EmojiHintToast(text: "请切换到 Emoji 键盘")
                        .transition(.opacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, JOSpacing.xl)
                }
            }
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
                    .fill(previewBackgroundColor)
                    .frame(width: Constants.previewSize, height: Constants.previewSize)
                    .shadow(color: previewBackgroundColor.opacity(0.35), radius: 18, x: 0, y: 8)
                    .shadow(color: previewBackgroundColor.opacity(0.2), radius: 8, x: 0, y: 4)

                JOIcon(
                    name: selectedIcon,
                    size: Constants.previewIconSize,
                    weight: .semibold,
                    color: Color.white.opacity(0.95)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
        .background(emojiInputField)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.sm) {
            Text("名称")
                .font(JOTypography.caption)
                .foregroundStyle(Color.white.opacity(Constants.sectionTitleOpacity))
                .tracking(2)

            ZStack(alignment: .trailing) {
                JOLimitedTextField(
                    text: $name,
                    placeholder: "最多 5 个字",
                    maxLength: Constants.nameLimit,
                    font: .systemFont(ofSize: 18, weight: .medium),
                    textColor: UIColor(JOColors.textPrimary),
                    placeholderColor: UIColor.white.withAlphaComponent(0.4),
                    returnKeyType: .done
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 28)

                Button {
                    name = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .opacity(name.isEmpty ? 0 : 1)
                .allowsHitTesting(!name.isEmpty)
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
        .opacity(isEmojiSelected ? 0.4 : 1)
        .allowsHitTesting(!isEmojiSelected)
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.md) {
            Text("图标")
                .font(JOTypography.caption)
                .foregroundStyle(Color.white.opacity(Constants.sectionTitleOpacity))
                .tracking(2)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: iconRows, spacing: Constants.iconSpacing) {
                    ForEach(Array(iconChoices.enumerated()), id: \.offset) { _, icon in
                        Button {
                            if icon == EmojiIconToken.placeholder {
                                if existing?.isSystem != true {
                                    emojiInput = ""
                                    showEmojiHint()
                                    isEmojiFieldFocused = true
                                }
                            } else {
                                selectedIcon = icon
                            }
                        } label: {
                            IconSwatch(
                                icon: icon,
                                isSelected: icon == EmojiIconToken.placeholder ? isEmojiSelected : selectedIcon == icon,
                                emojiValue: isEmojiSelected && icon == EmojiIconToken.placeholder
                                    ? String(selectedIcon.dropFirst(Constants.emojiPrefix.count))
                                    : Constants.emojiPlaceholderGlyph,
                                size: Constants.iconCellSize
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(existing?.isSystem == true && icon == EmojiIconToken.placeholder ? 0.35 : 1)
                        .disabled(existing?.isSystem == true && icon == EmojiIconToken.placeholder)
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

    private var iconChoices: [String] {
        [EmojiIconToken.placeholder] + CategoryIconCatalog.icons
    }

    private var iconGridHeight: CGFloat {
        Constants.iconCellSize * CGFloat(Constants.iconRowCount)
            + Constants.iconSpacing * CGFloat(Constants.iconRowCount - 1)
    }

    private var emojiInputField: some View {
        TextField("", text: $emojiInput)
            .focused($isEmojiFieldFocused)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .opacity(0.001)
            .frame(width: 1, height: 1)
            .onChange(of: emojiInput) {
                let emoji = emojiInput.firstEmojiOnly
                guard !emoji.isEmpty else { return }
                usesRandomColor = false
                selectedColorIndex = 0
                if let fallback = CategoryColorPalette.hexValues.first {
                    randomColorHex = fallback
                }
                selectedIcon = Constants.emojiPrefix + emoji
                emojiInput = ""
                isEmojiFieldFocused = false
            }
    }

    private func showEmojiHint() {
        guard !showsEmojiHint else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showsEmojiHint = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showsEmojiHint = false
            }
        }
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
    let emojiValue: String
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
                Group {
                    if icon == EmojiIconToken.placeholder {
                        Text(emojiValue)
                            .font(.system(size: size * 0.44, weight: .semibold))
                    } else {
                        JOIcon(
                            name: icon,
                            size: size * 0.44 - 3,
                            weight: .semibold,
                            color: isSelected ? Color.white.opacity(0.95) : Color.white.opacity(0.4)
                        )
                    }
                }
            )
    }
}

private extension String {
    var firstEmojiOnly: String {
        for char in self {
            if char.isEmojiCandidate {
                return String(char)
            }
        }
        return ""
    }
}

private extension Character {
    var isEmojiCandidate: Bool {
        let isEmoji = unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation || scalar.properties.isEmoji
        }
        let isPlainAlphaNumeric = unicodeScalars.allSatisfy { scalar in
            scalar.isASCII && CharacterSet.alphanumerics.contains(scalar)
        }
        return isEmoji && !isPlainAlphaNumeric
    }
}

private struct EmojiHintToast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(JOTypography.caption)
            .foregroundStyle(JOColors.textPrimary)
            .padding(.horizontal, JOSpacing.lg)
            .padding(.vertical, JOSpacing.sm)
            .background(
                Capsule()
                    .fill(JOColors.surface.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(JOColors.cardBorder.opacity(0.6), lineWidth: 1)
                    )
            )
    }
}
