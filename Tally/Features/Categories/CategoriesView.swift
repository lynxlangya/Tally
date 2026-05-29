import SwiftUI

struct CategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: CategoriesViewModel
    @State private var selectedType: BillType = .expense
    @State private var sheetState: CategorySheet?
    @State private var showsLimitAlert = false
    @State private var pendingDelete: CategoryRecord?

    init(repository: CategoryRepository) {
        _viewModel = StateObject(wrappedValue: CategoriesViewModel(repository: repository))
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
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TallyNavHeader(
                    title: TallyLocalization.text(.categories, locale: LanguageManager.shared.currentLocale),
                    onBack: { dismiss() },
                    trailing: AnyView(addButton)
                )

                Segmented(
                    value: $selectedType,
                    options: [
                        (BillType.expense, TallyLocalization.text(.expense, locale: LanguageManager.shared.currentLocale)),
                        (BillType.income, TallyLocalization.text(.income, locale: LanguageManager.shared.currentLocale))
                    ],
                    size: .md
                )
                .padding(.horizontal, TallySpacing.s6)
                .padding(.vertical, TallySpacing.s5)

                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 18) {
                        ForEach(viewModel.categories) { category in
                            Button {
                                sheetState = .edit(category)
                            } label: {
                                CategoryGridItem(category: category)
                            }
                            .buttonStyle(.plain)
                        }

                        AddCategoryItem(isDisabled: viewModel.isAtLimit) {
                            openNewCategory()
                        }
                    }
                    .padding(.horizontal, TallySpacing.s4)
                    .padding(.top, TallySpacing.s2)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }

            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(TallyType.body(12, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.86))
                        .padding(.horizontal, TallySpacing.s4)
                        .padding(.vertical, TallySpacing.s2)
                        .background(Color.tallySurface)
                        .clipShape(Capsule(style: .continuous))
                        .padding(.bottom, TallySpacing.s7)
                }
                .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
            viewModel.load(type: selectedType)
        }
        .onChange(of: selectedType, initial: false) { _, newValue in
            viewModel.load(type: newValue)
        }
        .tallySheet(item: $sheetState, heightFraction: 0.86) { state in
            CategoryEditSheet(
                type: state.type,
                existing: state.record,
                onSave: { name, iconKey, colorHex in
                    if let record = state.record {
                        return viewModel.updateCategory(
                            id: record.id,
                            name: name,
                            iconKey: iconKey,
                            colorHex: colorHex
                        )
                    } else {
                        return viewModel.addCategory(name: name, iconKey: iconKey, colorHex: colorHex)
                    }
                },
                onDelete: { record in
                    pendingDelete = record
                }
            )
        }
        .alert(viewModel.maxUserCategoriesMessage, isPresented: $showsLimitAlert) {
            Button(TallyLocalization.text(.gotIt, locale: LanguageManager.shared.currentLocale), role: .cancel) {}
        }
        .alert(TallyLocalization.text(.deleteCategoryConfirm, locale: LanguageManager.shared.currentLocale), isPresented: deleteAlertBinding) {
            Button(TallyLocalization.text(.cancel, locale: LanguageManager.shared.currentLocale), role: .cancel) {
                pendingDelete = nil
            }
            Button(TallyLocalization.text(.continueAction, locale: LanguageManager.shared.currentLocale), role: .destructive) {
                if let record = pendingDelete {
                    viewModel.deleteCategory(record)
                }
                pendingDelete = nil
            }
        }
    }

    private var addButton: some View {
        Button {
            openNewCategory()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tallyInkDim)
                .frame(width: 36, height: 36)
                .background(Color.tallySurface2)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TallyLocalization.text(.newCategory, locale: LanguageManager.shared.currentLocale))
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
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

    private func openNewCategory() {
        if viewModel.isAtLimit {
            showsLimitAlert = true
        } else {
            sheetState = .add(selectedType)
        }
    }
}

#Preview {
    let seed: [CategoryRecord] = [
        CategoryRecord(
            id: SystemCategoryID.uncategorizedExpense,
            type: .expense,
            name: "未分类",
            iconKey: "tag",
            colorHex: 0x6B6964,
            isSystem: true,
            sortOrder: 0
        ),
        CategoryRecord(
            id: UUID(),
            type: .expense,
            name: "餐饮",
            iconKey: "fork-knife",
            colorHex: 0xB8553E,
            isSystem: false,
            sortOrder: 1
        ),
        CategoryRecord(
            id: UUID(),
            type: .expense,
            name: "购物",
            iconKey: "shopping-cart",
            colorHex: 0x4D7148,
            isSystem: false,
            sortOrder: 2
        )
    ]
    NavigationStack {
        CategoriesView(repository: MockCategoryRepository(seed: seed))
    }
    .environment(\.appEnvironment, .preview)
}
