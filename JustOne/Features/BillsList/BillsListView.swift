import SwiftUI
import Foundation

struct BillsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: BillsListViewModel
    @State private var activeTrendIndex: Int?
    @State private var selectedCategory: CategorySheetTarget?
    @State private var editingBill: BillRecord?
    @State private var showsTimePicker = false

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository

    init(repository: BillRepository, categoryRepository: CategoryRepository) {
        self.billRepository = repository
        self.categoryRepository = categoryRepository
        _viewModel = StateObject(wrappedValue: BillsListViewModel(
            repository: repository,
            categoryRepository: categoryRepository
        ))
    }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                JOColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: JOSpacing.xl) {
                    BillsListHeader(
                        timeTitle: viewModel.timeTitle,
                        onBack: { dismiss() },
                        onTimeTap: { showsTimePicker = true },
                        selection: $viewModel.selectedType
                    )

                    BillsListSummaryView(
                        title: viewModel.summaryTitle,
                        totalCents: viewModel.summaryTotalCents,
                        change: viewModel.summaryChange,
                        type: viewModel.selectedType
                    )

                    BillsListTrendSection(
                        points: viewModel.trendPoints,
                        highlightIndex: viewModel.trendHighlightIndex,
                        valuesCents: viewModel.trendValuesCents,
                        axisLabels: viewModel.axisLabels,
                        activeIndex: $activeTrendIndex
                    )

                    BillsListRankingView(
                        title: viewModel.rankTitle,
                        items: viewModel.rankingItems,
                        onToggleSort: { viewModel.toggleRankSort() },
                        onSelectItem: { item in
                            selectedCategory = CategorySheetTarget(id: item.id)
                        }
                    )

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(JOTypography.caption)
                            .foregroundStyle(Color.red.opacity(0.8))
                    }
                }
                .padding(.horizontal, JOSpacing.lg)
                .padding(.top, JOSpacing.lg)
                .padding(.bottom, BillsListLayout.contentBottomPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                TimeRangeBar(selection: $viewModel.timeRange)
                    .padding(.horizontal, JOSpacing.xl)
                    .padding(.bottom, BillsListLayout.footerBottomOffset)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
        .task {
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .billDidChange)) { _ in
            viewModel.load()
        }
        .sheet(item: $selectedCategory, onDismiss: {
            selectedCategory = nil
        }) { target in
            BillsListCategoryDetailSheet(
                detail: viewModel.categoryDetail(for: target.id),
                onEdit: { billId in
                    guard let record = viewModel.billRecord(for: billId) else { return }
                    selectedCategory = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        editingBill = record
                    }
                }
            )
                .presentationDetents([.fraction(BillsListLayout.detailSheetHeightRatio)])
                .presentationDragIndicator(.hidden)
                .joPresentationCornerRadius(BillsListLayout.detailSheetCornerRadius)
                .joPresentationBackground(JOColors.surface.opacity(0.7))
        }
        .sheet(item: $editingBill, onDismiss: {
            editingBill = nil
        }) { bill in
            QuickEntryView(
                repository: billRepository,
                categoryRepository: categoryRepository,
                editingBill: bill
            )
        }
        .sheet(isPresented: $showsTimePicker) {
            JODatePickerSheet(
                mode: datePickerMode(for: viewModel.timeRange),
                years: viewModel.availableYears,
                selection: $viewModel.anchorDate,
                title: "选择时间"
            )
            .presentationDetents([.fraction(BillsListLayout.timePickerSheetHeightRatio)])
            .presentationDragIndicator(.hidden)
            .joPresentationCornerRadius(BillsListLayout.detailSheetCornerRadius)
            .joPresentationBackground(.clear)
        }
    }
}

private struct CategorySheetTarget: Identifiable {
    let id: UUID
}

private extension BillsListView {
    func datePickerMode(for range: BillsListViewModel.TimeRange) -> JODatePickerSheet.Mode {
        switch range {
        case .week:
            return .yearWeek
        case .month:
            return .yearMonth
        case .year:
            return .year
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

    @ViewBuilder
    func joPresentationCornerRadius(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            presentationCornerRadius(radius)
        } else {
            self
        }
    }
}

#Preview {
    let today = Date()
    let dayKey = DayKeyFormatter.dayKey(for: today)
    let sampleBills: [BillRecord] = [
        BillRecord(
            id: UUID(),
            type: .expense,
            amount: Money(cents: 124050),
            occurredAtUTC: today,
            tzId: TimeZone.current.identifier,
            tzOffset: TimeZone.current.secondsFromGMT(),
            occurredLocalDate: dayKey,
            note: "房租",
            categoryId: SystemCategoryID.uncategorizedExpense,
            isFromRecurring: false,
            createdAt: today,
            updatedAt: today,
            deletedAt: nil,
            trashUntil: nil
        ),
        BillRecord(
            id: UUID(),
            type: .expense,
            amount: Money(cents: 31012),
            occurredAtUTC: today,
            tzId: TimeZone.current.identifier,
            tzOffset: TimeZone.current.secondsFromGMT(),
            occurredLocalDate: dayKey,
            note: "餐饮",
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            isFromRecurring: false,
            createdAt: today,
            updatedAt: today,
            deletedAt: nil,
            trashUntil: nil
        )
    ]

    let categories: [CategoryRecord] = [
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
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            type: .expense,
            name: "餐饮",
            iconKey: "fork.knife",
            colorHex: 0xF97316,
            isSystem: false,
            sortOrder: 1
        )
    ]

    let billRepo = MockBillRepository(seed: sampleBills)
    let categoryRepo = MockCategoryRepository(seed: categories)

    NavigationStack {
        BillsListView(repository: billRepo, categoryRepository: categoryRepo)
    }
}
