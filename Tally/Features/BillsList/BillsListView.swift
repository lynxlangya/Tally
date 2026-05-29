import SwiftUI

struct BillsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @Environment(\.tallyThemeColors) private var themeColors
    @StateObject private var viewModel: BillsListViewModel
    @State private var selectedCategory: CategorySheetTarget?
    @State private var editingBill: BillRecord?
    @State private var showsJumpPicker = false

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private let hidesTabBarOnAppear: Bool

    init(
        repository: BillRepository,
        categoryRepository: CategoryRepository,
        hidesTabBarOnAppear: Bool = true
    ) {
        self.billRepository = repository
        self.categoryRepository = categoryRepository
        self.hidesTabBarOnAppear = hidesTabBarOnAppear
        _viewModel = StateObject(wrappedValue: BillsListViewModel(
            repository: repository,
            categoryRepository: categoryRepository
        ))
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    rangeBar
                        .padding(.top, TallySpacing.s5)

                    StatsSummaryCard(summary: viewModel.summary)
                        .padding(.top, TallySpacing.s3)

                    StatsTrendCard(
                        valuesCents: viewModel.trend30Cents,
                        normalized: viewModel.trendPoints,
                        peak: viewModel.trendPeak,
                        axisLabels: viewModel.axisLabels
                    )
                    .padding(.top, TallySpacing.s3)

                    StatsCategoryRanking(
                        items: viewModel.categoryRanking,
                        totalCount: viewModel.categoryRankingTotalCount,
                        onSelect: { item in selectedCategory = CategorySheetTarget(id: item.id) }
                    )
                    .padding(.top, TallySpacing.s7)

                    StatsBillsList(
                        groupedRows: viewModel.groupedRows,
                        dayKeys: viewModel.dayKeys,
                        onSelect: { item in
                            if let record = viewModel.billRecord(for: item.id) {
                                editingBill = record
                            }
                        }
                    )
                    .padding(.top, TallySpacing.s7)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(TallyType.body(12, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.82))
                            .padding(.horizontal, BillsListLayout.horizontalPadding)
                            .padding(.top, TallySpacing.s4)
                    }
                }
                .padding(.top, TallySpacing.s1)
                .padding(.bottom, BillsListLayout.contentBottomPadding)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(!hidesTabBarOnAppear)
        }
        .task {
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .billDidChange)) { _ in
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .categoryDidChange)) { _ in
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
            .presentationCornerRadius(BillsListLayout.detailSheetCornerRadius)
            .presentationBackground(Color.tallySurface)
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
        .sheet(isPresented: $showsJumpPicker) {
            BillsListPeriodJumpSheet(viewModel: viewModel)
                .presentationDetents([.height(viewModel.timeRange == .custom ? BillsListLayout.customRangeSheetHeight : BillsListLayout.jumpSheetHeight)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(BillsListLayout.detailSheetCornerRadius)
                .presentationBackground(Color.tallySurface)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: TallySpacing.s4) {
            VStack(alignment: .leading, spacing: TallySpacing.s1) {
                Eyebrow("账本")
                Text("账本")
                    .font(TallyType.display(30, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            Segmented(
                value: $viewModel.selectedType,
                options: [(BillType.expense, "支出"), (BillType.income, "收入")],
                size: .sm
            )
        }
        .padding(.horizontal, BillsListLayout.horizontalPadding)
    }

    private var rangeBar: some View {
        VStack(spacing: TallySpacing.s3) {
            Segmented(
                value: $viewModel.timeRange,
                options: BillsListViewModel.TimeRange.allCases.map { ($0, $0.title) },
                size: .sm
            )

            BillsListPeriodNavigator(
                title: viewModel.timeTitle,
                showsArrows: viewModel.timeRange != .custom,
                canGoNext: viewModel.canGoNext,
                onPrevious: { viewModel.goPrevious() },
                onNext: { viewModel.goNext() },
                onTitleTap: { showsJumpPicker = true }
            )
        }
        .padding(.horizontal, BillsListLayout.horizontalPadding)
    }
}

private struct CategorySheetTarget: Identifiable {
    let id: UUID
}

private struct StatsSummaryCard: View {
    let summary: BillsListViewModel.Summary

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        VStack(spacing: TallySpacing.s4) {
            HStack(spacing: TallySpacing.s4) {
                summaryCell(title: "支出", cents: summary.expenseCents, sign: .expense, alignment: .leading)
                summaryCell(title: "收入", cents: summary.incomeCents, sign: .income, alignment: .trailing)
            }

            Rectangle()
                .fill(Color.tallyLine)
                .frame(height: 0.5)

            HStack {
                Text("结余")
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkDim)

                Spacer()

                TallyAmountText(
                    cents: abs(summary.balanceCents),
                    sign: summary.balanceCents >= 0 ? .income : .expense,
                    size: 22,
                    weight: .semibold,
                    color: summary.balanceCents >= 0 ? themeColors.accent : .tallyInk
                )
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            }
        }
        .padding(20)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: BillsListLayout.summaryCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BillsListLayout.summaryCornerRadius, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
        .padding(.horizontal, BillsListLayout.horizontalPadding)
    }

    private func summaryCell(
        title: String,
        cents: Int,
        sign: TallyAmountText.Sign,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: TallySpacing.s1) {
            Eyebrow(title)
            TallyAmountText(cents: cents, sign: sign, size: 24, weight: .medium, color: .tallyInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

private struct StatsTrendCard: View {
    let valuesCents: [Int]
    let normalized: [Double]
    let peak: BillsListViewModel.TrendPeak?
    let axisLabels: [String]

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        VStack(spacing: TallySpacing.s3) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("30 日支出")
                Spacer()
                Text(peakText)
                    .font(TallyType.num(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
            }

            GeometryReader { proxy in
                Sparkline(
                    data: normalized,
                    color: themeColors.accent,
                    fill: true,
                    dot: true,
                    dotIndex: peak?.index,
                    baseline: true,
                    width: max(proxy.size.width, 1),
                    height: BillsListLayout.trendHeight
                )
            }
            .frame(height: BillsListLayout.trendHeight)

            HStack {
                ForEach(Array(axisLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(TallyType.body(10, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                        .frame(
                            maxWidth: .infinity,
                            alignment: index == 0 ? .leading : (index == axisLabels.count - 1 ? .trailing : .center)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: BillsListLayout.summaryCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BillsListLayout.summaryCornerRadius, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
        .padding(.horizontal, BillsListLayout.horizontalPadding)
    }

    private var peakText: String {
        guard let peak else { return "峰值 - \(MoneyFormatter.wholeYuanString(fromCents: 0))" }
        return "峰值 \(peak.label) \(MoneyFormatter.wholeYuanString(fromCents: peak.amountCents))"
    }
}

private struct StatsCategoryRanking: View {
    let items: [BillsListViewModel.RankingItem]
    let totalCount: Int
    let onSelect: (BillsListViewModel.RankingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("分类排名")
                Spacer()
                Text("共 \(totalCount) 项 · 看全部")
                    .font(TallyType.body(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }
            .padding(.horizontal, BillsListLayout.horizontalPadding)

            if items.isEmpty {
                Text("没有分类记录。")
                    .font(TallyType.body(13, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BillsListLayout.horizontalPadding)
            } else {
                VStack(spacing: BillsListLayout.rankingSpacing) {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            RankingRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BillsListLayout.horizontalPadding)
            }
        }
    }
}

private struct RankingRow: View {
    let item: BillsListViewModel.RankingItem

    var body: some View {
        HStack(alignment: .center, spacing: TallySpacing.s3) {
            CategoryTile(iconName: item.iconName, color: itemColor, size: 28, radius: TallyRadii.sm)

            VStack(spacing: 5) {
                HStack {
                    Text(item.title)
                        .font(TallyType.body(13, weight: .medium))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)

                    Text("· \(item.count)")
                        .font(TallyType.body(11, weight: .regular))
                        .foregroundStyle(Color.tallyInkFaint)

                    Spacer()

                    Text(MoneyFormatter.wholeYuanString(fromCents: item.amountCents))
                        .font(TallyType.num(13, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                }

                GeometryReader { proxy in
                    let width = max(proxy.size.width * CGFloat(item.percent), 3)
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.tallySurface2)
                        Capsule(style: .continuous)
                            .fill(itemColor)
                            .frame(width: width)
                            .animation(.tallyEmph, value: item.percent)
                    }
                }
                .frame(height: BillsListLayout.rankBarHeight)
            }
        }
    }

    private var itemColor: Color {
        if let hex = item.iconColorHex {
            return Color(hex: hex)
        }
        return .catAsh
    }
}

private struct StatsBillsList: View {
    let groupedRows: [String: [BillsListViewModel.RowItem]]
    let dayKeys: [String]
    let onSelect: (BillsListViewModel.RowItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s3) {
            Eyebrow("明细")
                .padding(.horizontal, BillsListLayout.horizontalPadding)

            if dayKeys.isEmpty {
                Text("没有明细。")
                    .font(TallyType.body(13, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .padding(.horizontal, BillsListLayout.horizontalPadding)
                    .padding(.top, TallySpacing.s3)
            } else {
                VStack(spacing: TallySpacing.s5) {
                    ForEach(dayKeys, id: \.self) { dayKey in
                        let rows = groupedRows[dayKey] ?? []
                        VStack(alignment: .leading, spacing: TallySpacing.s2) {
                            Text(dayKey)
                                .font(TallyType.num(11, weight: .semibold))
                                .foregroundStyle(Color.tallyInkFaint)
                                .padding(.horizontal, BillsListLayout.horizontalPadding)

                            VStack(spacing: 0) {
                                ForEach(rows) { item in
                                    Button {
                                        onSelect(item)
                                    } label: {
                                        DenseBillRow(item: item)
                                    }
                                    .buttonStyle(DenseBillRowButtonStyle())
                                }
                            }
                            .background(Color.tallySurface)
                        }
                    }
                }
            }
        }
    }
}

private struct DenseBillRow: View {
    let item: BillsListViewModel.RowItem

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        HStack(spacing: TallySpacing.s3) {
            CategoryTile(iconName: item.iconName, color: iconColor, size: 32, radius: TallyRadii.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(TallyType.body(14, weight: .medium))
                    .foregroundStyle(Color.tallyInk)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(TallyType.body(11, weight: .regular))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TallyAmountText(
                cents: item.amountCents,
                sign: item.isIncome ? .income : .expense,
                size: 15,
                weight: .semibold,
                color: item.isIncome ? themeColors.accent : .tallyInk
            )
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, BillsListLayout.horizontalPadding)
        .padding(.vertical, TallySpacing.s3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private var iconColor: Color {
        if let hex = item.iconColorHex {
            return Color(hex: hex)
        }
        return .catAsh
    }

    private var accessibilitySummary: String {
        let typeText = item.isIncome ? "收入" : "支出"
        let amountText = MoneyFormatter.string(fromCents: item.amountCents)
        return "\(item.title)，\(item.subtitle)，\(typeText)，\(amountText)"
    }
}

private struct DenseBillRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.tallySurface2 : Color.clear)
            .animation(.tallyFast, value: configuration.isPressed)
    }
}

private struct StatsDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tallyThemeColors) private var themeColors
    @Binding var selection: Date

    var body: some View {
        VStack(spacing: TallySpacing.s4) {
            HStack {
                Text("选择时间")
                    .font(TallyType.body(17, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)

                Spacer()

                Button("完成") {
                    dismiss()
                }
                .font(TallyType.body(14, weight: .semibold))
                .foregroundStyle(themeColors.accent)
                .buttonStyle(.plain)
            }

            DatePicker("选择时间", selection: $selection, displayedComponents: [.date])
                .datePickerStyle(.wheel)
                .labelsHidden()
                .tint(themeColors.accent)
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

#Preview("BillsList") {
    let sample = BillsListViewModel.makeMockData(anchor: BillsListViewModel.mockAnchorDate)
    NavigationStack {
        BillsListView(
            repository: MockBillRepository(seed: sample.bills),
            categoryRepository: MockCategoryRepository(seed: sample.categories)
        )
    }
    .preferredColorScheme(.dark)
}
