import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: CategoriesViewModel
    @State private var selectedIndex = 0
    @State private var sheetState: CategorySheet?
    @State private var showsLimitAlert = false
    @State private var pendingDelete: CategoryRecord?
    @State private var isReordering = false
    @State private var draggingCategory: CategoryRecord?

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
                .allowsHitTesting(!isReordering)
                .opacity(isReordering ? 0.5 : 1)

            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: JOSpacing.xl) {
                    ForEach(viewModel.categories) { category in
                        categoryCell(for: category)
                    }

                    AddCategoryItem(isDisabled: viewModel.isAtLimit || isReordering) {
                        if viewModel.isAtLimit {
                            showsLimitAlert = true
                        } else if !isReordering {
                            sheetState = .add(selectedType)
                        }
                    }
                }
                .padding(.top, JOSpacing.lg)
            }
            .scrollDisabled(isReordering)

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
            isReordering = false
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

            if isReordering {
                Button("完成") {
                    exitReorderingMode()
                }
                .font(JOTypography.body)
                .foregroundStyle(JOColors.accent)
                .frame(width: 36, height: 36)
            } else {
                JOIconButton(systemName: "arrow.up.arrow.down", size: 36) {
                    enterReorderingMode()
                }
            }
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

    @ViewBuilder
    private func categoryCell(for category: CategoryRecord) -> some View {
        let content = CategoryGridItem(
            category: category,
            color: categoryDisplayColor(for: category)
        )
        .modifier(WiggleEffect(isActive: isReordering))
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isReordering else { return }
            sheetState = .edit(category)
        }

        if isReordering {
            content
                .onDrag {
                    draggingCategory = category
                    return NSItemProvider(object: category.id.uuidString as NSString)
                } preview: {
                    dragPreview(for: category)
                }
                .onDrop(
                    of: [.text],
                    delegate: CategoryDropDelegate(
                        target: category,
                        isReordering: isReordering,
                        dragging: $draggingCategory,
                        onMove: { source, destination in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.moveCategory(from: source, to: destination)
                            }
                        },
                        onCommit: {
                            viewModel.persistOrder()
                        }
                    )
                )
        } else {
            content
        }
    }

    private func categoryDisplayColor(for category: CategoryRecord) -> Color {
        let hex = category.colorHex.map { UInt32($0) }
            ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }

    private func dragPreview(for category: CategoryRecord) -> some View {
        CategoryGridItem(
            category: category,
            color: categoryDisplayColor(for: category)
        )
        .background(Color.clear)
        .compositingGroup()
    }

    private func enterReorderingMode() {
        guard !isReordering else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            isReordering = true
        }
    }

    private func exitReorderingMode() {
        guard isReordering else { return }
        isReordering = false
        viewModel.persistOrder()
    }
}

private struct WiggleEffect: ViewModifier {
    let isActive: Bool
    @State private var phase = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isActive ? (phase ? 1.5 : -1.5) : 0))
            .scaleEffect(isActive ? 0.99 : 1)
            .onAppear {
                if isActive {
                    start()
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    start()
                } else {
                    stop()
                }
            }
    }

    private func start() {
        phase = false
        withAnimation(.easeInOut(duration: 0.14).repeatForever(autoreverses: true)) {
            phase = true
        }
    }

    private func stop() {
        withTransaction(Transaction(animation: .none)) {
            phase = false
        }
    }
}

private struct CategoryDropDelegate: DropDelegate {
    let target: CategoryRecord
    let isReordering: Bool
    @Binding var dragging: CategoryRecord?
    let onMove: (CategoryRecord, CategoryRecord) -> Void
    let onCommit: () -> Void

    func dropEntered(info: DropInfo) {
        guard isReordering, let dragging, dragging.id != target.id else { return }
        onMove(dragging, target)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        onCommit()
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
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
