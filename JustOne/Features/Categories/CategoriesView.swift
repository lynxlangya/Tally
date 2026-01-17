import SwiftUI

struct CategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: CategoriesViewModel
    @State private var selectedIndex = 0
    @State private var showsAddSheet = false
    @State private var showsLimitAlert = false

    private enum Constants {
        static let headerTitleSize: CGFloat = 18
    }

    init(repository: CategoryRepository) {
        _viewModel = StateObject(wrappedValue: CategoriesViewModel(repository: repository))
    }

    private var selectedType: BillType {
        selectedIndex == 0 ? .expense : .income
    }

    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            header
            JOSegmentedControl(items: ["支出", "收入"], selectedIndex: $selectedIndex)

            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: JOSpacing.xl) {
                    ForEach(viewModel.categories) { category in
                        CategoryGridItem(category: category)
                    }

                    AddCategoryItem(isDisabled: viewModel.isAtLimit) {
                        if viewModel.isAtLimit {
                            showsLimitAlert = true
                        } else {
                            showsAddSheet = true
                        }
                    }
                }
                .padding(.top, JOSpacing.lg)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(JOTypography.caption)
                    .foregroundStyle(Color.red.opacity(0.8))
            }
        }
        .padding(.horizontal, JOSpacing.lg)
        .padding(.top, JOSpacing.lg)
        .background(JOColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
            viewModel.load(type: selectedType)
        }
        .onChange(of: selectedIndex, initial: false) { _, newValue in
            viewModel.load(type: newValue == 0 ? .expense : .income)
        }
        .sheet(isPresented: $showsAddSheet) {
            CategoryAddSheet(type: selectedType) { name, iconKey in
                viewModel.addCategory(name: name, iconKey: iconKey)
            }
        }
        .alert("最多新增 30 个分类", isPresented: $showsLimitAlert) {
            Button("知道了", role: .cancel) {}
        }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: JOSpacing.lg), count: 4)
    }

    private var header: some View {
        HStack {
            JOBackButton {
                dismiss()
            }

            Spacer()

            Text("类别管理")
                .font(.system(size: Constants.headerTitleSize, weight: .semibold))
                .foregroundStyle(JOColors.textSecondary)
                .tracking(2)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
    }
}

private struct CategoryGridItem: View {
    let category: CategoryRecord

    var body: some View {
        VStack(spacing: JOSpacing.sm) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(JOColors.surface)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(JOColors.cardBorder, lineWidth: 1)
                    )

                Image(systemName: category.iconKey)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(category.isSystem ? JOColors.textSecondary : JOColors.textPrimary)

                if category.isSystem {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(JOColors.textPrimary)
                        .padding(4)
                        .background(JOColors.profileRowBackground)
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
            }

            Text(category.name)
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)
                .lineLimit(1)
        }
    }
}

private struct AddCategoryItem: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: JOSpacing.sm) {
                Circle()
                    .stroke(
                        JOColors.textSecondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(JOColors.textSecondary)
                    )

                Text("添加类别")
                    .font(JOTypography.caption)
                    .foregroundStyle(JOColors.textSecondary)
                    .lineLimit(1)
            }
            .opacity(isDisabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
    }
}

private struct CategoryAddSheet: View {
    let type: BillType
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = CategoryIconCatalog.icons.first ?? "questionmark"
    @State private var selectedColorIndex = 0
    @State private var randomColor = CategoryColorPalette.random()
    @State private var usesRandomColor = false
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
        static let iconRowCount = 4
        static let iconSpacing: CGFloat = 12
        static let sectionTitleOpacity: CGFloat = 0.45
        static let saveBottomPadding: CGFloat = 0
    }

    private var selectedColor: Color {
        usesRandomColor ? randomColor : CategoryColorPalette.colors[selectedColorIndex]
    }

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = proxy.safeAreaInsets.bottom
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

            saveButton
                    .padding(.top, 5)
            }
            .padding(.horizontal, JOSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(JOColors.background.ignoresSafeArea())
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
                ForEach(CategoryColorPalette.colors.indices, id: \.self) { index in
                    let color = CategoryColorPalette.colors[index]
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
                    color: randomColor,
                    isSelected: usesRandomColor,
                    size: Constants.colorSwatchSize
                ) {
                    randomColor = CategoryColorPalette.random()
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
                                highlight: selectedColor,
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
            onSave(trimmed, selectedIcon)
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

private struct ColorSwatch: View {
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

private struct RandomColorSwatch: View {
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

private struct IconSwatch: View {
    let icon: String
    let isSelected: Bool
    let highlight: Color
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

private enum CategoryColorPalette {
    static let colors: [Color] = [
        Color(hex: 0x13EC37),
        Color(hex: 0x3B82F6),
        Color(hex: 0xEF4444),
        Color(hex: 0xEAB308),
        Color(hex: 0xA855F7),
        Color(hex: 0xF97316),
        Color(hex: 0xEC4899),
        Color(hex: 0x06B6D4),
        Color(hex: 0x8B5CF6),
        Color(hex: 0x14B8A6),
        Color(hex: 0xF43F5E),
        Color(hex: 0x22C55E),
        Color(hex: 0x38BDF8),
        Color(hex: 0x6366F1),
        Color(hex: 0xF472B6)
    ]

    static func random() -> Color {
        let hue = Double.random(in: 0...1)
        let saturation = Double.random(in: 0.55...0.85)
        let brightness = Double.random(in: 0.75...0.95)
        return Color(hue: hue, saturation: saturation, brightness: brightness, opacity: 1)
    }
}

private enum CategoryIconCatalog {
    static let icons: [String] = [
        // Food & Daily
        "fork.knife","cup.and.saucer.fill","takeoutbag.and.cup.and.straw.fill","birthday.cake.fill",
        "cart.fill","bag.fill","tag.fill","basket.fill","drop.fill",

        // Transport
        "bus","tram.fill","train.side.front.car","car.fill","bicycle","airplane",
        "fuelpump.fill","parkingsign.circle.fill","ticket.fill",

        // Home & Bills
        "house.fill","building.2.fill","bed.double.fill","lightbulb.fill","flame.fill",
        "wifi","tv.fill","wrench.and.screwdriver.fill",

        // Finance & Income
        "banknote.fill","creditcard.fill","wallet.pass.fill","dollarsign.circle.fill",
        "briefcase.fill","chart.line.uptrend.xyaxis","percent","doc.text.fill",

        // Health
        "cross.case.fill","pills.fill","stethoscope","heart.fill","figure.walk","dumbbell.fill",

        // Education
        "graduationcap.fill","book.fill","pencil","laptopcomputer",

        // Entertainment & Social
        "film","music.note","gamecontroller.fill","theatermasks.fill","person.2.fill","gift.fill",

        // Comms & Subscription
        "phone.fill","message.fill","envelope.fill","calendar","repeat",

        // Family & Others
        "pawprint.fill","leaf.fill","paintbrush.fill","scissors","tshirt.fill","bag.badge.plus"
    ]
}


private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

#Preview {
    let seed: [CategoryRecord] = [
        CategoryRecord(
            id: SystemCategoryID.uncategorizedExpense,
            type: .expense,
            name: "未分类",
            iconKey: "questionmark",
            isSystem: true,
            sortOrder: 0
        ),
        CategoryRecord(
            id: UUID(),
            type: .expense,
            name: "餐饮",
            iconKey: "fork.knife",
            isSystem: false,
            sortOrder: 1
        ),
        CategoryRecord(
            id: UUID(),
            type: .expense,
            name: "购物",
            iconKey: "cart.fill",
            isSystem: false,
            sortOrder: 2
        )
    ]
    let repository = MockCategoryRepository(seed: seed)
    NavigationStack {
        CategoriesView(repository: repository)
    }
    .environment(\.appEnvironment, .preview)
}
