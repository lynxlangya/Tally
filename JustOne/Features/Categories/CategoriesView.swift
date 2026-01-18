import SwiftUI

struct CategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: CategoriesViewModel
    @State private var selectedIndex = 0
    @State private var sheetState: CategorySheet?
    @State private var showsLimitAlert = false
    @State private var pendingDelete: CategoryRecord?

    private enum Constants {
        static let headerTitleSize: CGFloat = 18
    }

    init(repository: CategoryRepository) {
        _viewModel = StateObject(wrappedValue: CategoriesViewModel(repository: repository))
    }

    private var selectedType: BillType {
        selectedIndex == 0 ? .expense : .income
    }

    private enum CategorySheet: Identifiable {
        case add(BillType)
        case edit(CategoryRecord)

        var id: String {
            switch self {
            case .add(let type):
                return "add-\(type.rawValue)"
            case .edit(let record):
                return record.id.uuidString
            }
        }

        var type: BillType {
            switch self {
            case .add(let type):
                return type
            case .edit(let record):
                return record.type
            }
        }

        var record: CategoryRecord? {
            switch self {
            case .add:
                return nil
            case .edit(let record):
                return record
            }
        }
    }

    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            header
            JOSegmentedControl(items: ["支出", "收入"], selectedIndex: $selectedIndex)

            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: JOSpacing.xl) {
                    ForEach(viewModel.categories) { category in
                        Button {
                            sheetState = .edit(category)
                        } label: {
                            CategoryGridItem(
                                category: category,
                                color: categoryDisplayColor(for: category)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    AddCategoryItem(isDisabled: viewModel.isAtLimit) {
                        if viewModel.isAtLimit {
                            showsLimitAlert = true
                        } else {
                            sheetState = .add(selectedType)
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
        .sheet(item: $sheetState) { state in
            CategoryEditSheet(
                type: state.type,
                existing: state.record,
                onSave: { name, iconKey, colorHex in
                    if let record = state.record {
                        viewModel.updateCategory(
                            id: record.id,
                            name: name,
                            iconKey: iconKey,
                            colorHex: colorHex
                        )
                    } else {
                        viewModel.addCategory(name: name, iconKey: iconKey, colorHex: colorHex)
                    }
                },
                onDelete: { record in
                    pendingDelete = record
                }
            )
        }
        .alert("最多新增 30 个分类", isPresented: $showsLimitAlert) {
            Button("知道了", role: .cancel) {}
        }
        .alert("该类别下所有账单归类到未分类，是否继续？", isPresented: deleteAlertBinding) {
            Button("取消", role: .cancel) {
                pendingDelete = nil
            }
            Button("继续", role: .destructive) {
                if let record = pendingDelete {
                    viewModel.deleteCategory(record)
                }
                pendingDelete = nil
            }
        }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: JOSpacing.lg), count: 4)
    }

    private var header: some View {
        JOHeaderBar(
            title: "类别管理",
            titleFont: .system(size: Constants.headerTitleSize, weight: .semibold),
            titleColor: JOColors.textSecondary,
            titleTracking: 2
        ) {
            dismiss()
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDelete = nil
                }
            }
        )
    }

    private func categoryDisplayColor(for category: CategoryRecord) -> Color {
        let hex = category.colorHex.map { UInt32($0) }
            ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }
}

#Preview {
    let seed: [CategoryRecord] = [
        CategoryRecord(
            id: SystemCategoryID.uncategorizedExpense,
            type: .expense,
            name: "未分类",
            iconKey: "questionmark",
            colorHex: 0x13EC37,
            isSystem: true,
            sortOrder: 0
        ),
        CategoryRecord(
            id: UUID(),
            type: .expense,
            name: "餐饮",
            iconKey: "fork.knife",
            colorHex: 0xF97316,
            isSystem: false,
            sortOrder: 1
        ),
        CategoryRecord(
            id: UUID(),
            type: .expense,
            name: "购物",
            iconKey: "cart.fill",
            colorHex: 0x3B82F6,
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
