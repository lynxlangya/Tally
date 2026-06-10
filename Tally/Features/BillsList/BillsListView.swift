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
    private let suggestionService: CategorySuggestionService
    private let hidesTabBarOnAppear: Bool

    init(
        repository: BillRepository,
        categoryRepository: CategoryRepository,
        suggestionService: CategorySuggestionService,
        hidesTabBarOnAppear: Bool = true
    ) {
        self.billRepository = repository
        self.categoryRepository = categoryRepository
        self.suggestionService = suggestionService
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
                        .padding(.top, BillsListLayout.rangeTopPadding)

                    BillsListHeroSummary(
                        summary: viewModel.summary,
                        selectedType: viewModel.selectedType,
                        selectedTotalCents: viewModel.selectedTotalCents,
                        eyebrow: viewModel.periodEyebrow,
                        typeTitle: viewModel.selectedTypeTitle
                    )
                    .padding(.top, BillsListLayout.heroTopPadding)

                    StatsTrendCard(
                        title: viewModel.trendTitle,
                        valuesCents: viewModel.trend30Cents,
                        normalized: viewModel.trendPoints,
                        peak: viewModel.trendPeak,
                        axisLabels: viewModel.axisLabels
                    )
                    .padding(.top, BillsListLayout.trendTopPadding)

                    StatsCategoryRanking(
                        items: viewModel.categoryRanking,
                        totalCount: viewModel.categoryRankingTotalCount,
                        onSelect: { item in selectedCategory = CategorySheetTarget(id: item.id) }
                    )
                    .padding(.top, TallySpacing.s6)

                    StatsBillsList(
                        groupedRows: viewModel.groupedRows,
                        dayKeys: viewModel.dayKeys,
                        onSelect: { item in
                            if let record = viewModel.billRecord(for: item.id) {
                                editingBill = record
                            }
                        }
                    )
                    .padding(.top, TallySpacing.s6)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(TallyType.body(12, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.82))
                            .padding(.horizontal, BillsListLayout.horizontalPadding)
                            .padding(.top, TallySpacing.s4)
                    }
                }
                .padding(.top, BillsListLayout.contentTopPadding)
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
            .presentationBackground(Color.tallyBg)
        }
        .sheet(item: $editingBill, onDismiss: {
            editingBill = nil
        }) { bill in
            QuickEntryView(
                repository: billRepository,
                categoryRepository: categoryRepository,
                suggestionService: suggestionService,
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
            Text(TallyLocalization.text(.bills, locale: LanguageManager.shared.currentLocale))
                .font(TallyType.display(28, weight: .semibold))
                .foregroundStyle(Color.tallyInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer()

            Segmented(
                value: $viewModel.selectedType,
                options: [
                    (BillType.expense, TallyLocalization.text(.expense, locale: LanguageManager.shared.currentLocale)),
                    (BillType.income, TallyLocalization.text(.income, locale: LanguageManager.shared.currentLocale))
                ],
                size: .sm
            )
        }
        .padding(.horizontal, BillsListLayout.horizontalPadding)
    }

    private var rangeBar: some View {
        HStack(alignment: .center, spacing: TallySpacing.s3) {
            CompactRangeSegmented(
                value: $viewModel.timeRange,
                options: BillsListViewModel.TimeRange.allCases.map { ($0, $0.title) }
            )

            Spacer(minLength: TallySpacing.s1)

            BillsListPeriodNavigator(
                title: viewModel.periodNavigationTitle,
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

private struct CompactRangeSegmented: View {
    @Binding var value: BillsListViewModel.TimeRange
    let options: [(BillsListViewModel.TimeRange, String)]

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.0) { option in
                let active = option.0 == value
                Button {
                    withAnimation(.tallyFast) {
                        value = option.0
                    }
                } label: {
                    Text(option.1)
                        .font(TallyType.body(12, weight: .semibold))
                        .foregroundStyle(active ? themeColors.accentInk : Color.tallyInkDim)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(active ? themeColors.accent : Color.clear)
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .frame(width: BillsListLayout.rangeSegmentedWidth)
        .background(Color.tallySurface.opacity(0.82))
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }
}

private struct BillsListHeroSummary: View {
    let summary: BillsListViewModel.Summary
    let selectedType: BillType
    let selectedTotalCents: Int
    let eyebrow: String
    let typeTitle: String

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            VStack(alignment: .leading, spacing: TallySpacing.s2) {
                Text("\(eyebrow) · \(typeTitle)")
                    .font(TallyType.body(13, weight: .semibold))
                    .foregroundStyle(Color.tallyInkDim)

                TallyAmountText(
                    cents: selectedTotalCents,
                    sign: selectedType == .expense ? .expense : .income,
                    size: BillsListLayout.heroAmountSize,
                    weight: .semibold,
                    color: .tallyInk,
                    animationStyle: .numeric
                )
                .lineLimit(1)
                .minimumScaleFactor(0.56)
            }

            Rectangle()
                .fill(Color.tallyLine)
                .frame(height: 0.5)

            HStack(alignment: .top, spacing: TallySpacing.s7) {
                miniMetric(title: TallyLocalization.text(.income, locale: LanguageManager.shared.currentLocale), cents: summary.incomeCents, sign: .income, color: .tallyInkDim)
                miniMetric(
                    title: TallyLocalization.text(.balance, locale: LanguageManager.shared.currentLocale),
                    cents: abs(summary.balanceCents),
                    sign: summary.balanceCents >= 0 ? .income : .expense,
                    color: summary.balanceCents >= 0 ? themeColors.accent : .tallyInk
                )
            }
        }
        .padding(.horizontal, BillsListLayout.horizontalPadding)
    }

    private func miniMetric(
        title: String,
        cents: Int,
        sign: TallyAmountText.Sign,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: TallySpacing.s1) {
            Text(title)
                .font(TallyType.body(12, weight: .semibold))
                .foregroundStyle(Color.tallyInkDim)

            TallyAmountText(
                cents: cents,
                sign: sign,
                size: 15,
                weight: .semibold,
                color: color,
                animationStyle: .numeric
            )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct StatsTrendCard: View {
    let title: String
    let valuesCents: [Int]
    let normalized: [Double]
    let peak: BillsListViewModel.TrendPeak?
    let axisLabels: [String]

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        VStack(spacing: TallySpacing.s3) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow(title)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: BillsListLayout.summaryCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BillsListLayout.summaryCornerRadius, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
        .padding(.horizontal, BillsListLayout.horizontalPadding)
    }

    private var peakText: String {
        let locale = LanguageManager.shared.currentLocale
        guard let peak else {
            return TallyLocalization.format(
                "peak_empty_format",
                locale: locale,
                MoneyFormatter.wholeYuanString(fromCents: 0, locale: locale)
            )
        }
        return TallyLocalization.format(
            "peak_format",
            locale: locale,
            peak.label,
            MoneyFormatter.wholeYuanString(fromCents: peak.amountCents, locale: locale)
        )
    }
}

private struct StatsCategoryRanking: View {
    let items: [BillsListViewModel.RankingItem]
    let totalCount: Int
    let onSelect: (BillsListViewModel.RankingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s4) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(TallyLocalization.text(.categoryRanking, locale: LanguageManager.shared.currentLocale))
                Spacer()
                Text(TallyLocalization.format(.categoryCountSummary, locale: LanguageManager.shared.currentLocale, totalCount))
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }
            .padding(.horizontal, BillsListLayout.horizontalPadding)

            if items.isEmpty {
                Text(TallyLocalization.text(.noCategoryRecords, locale: LanguageManager.shared.currentLocale))
                    .font(TallyType.body(12, weight: .medium))
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
            CategoryTile(iconName: item.iconName, color: itemColor, size: 38, radius: TallyRadii.md)

            VStack(spacing: TallySpacing.s2) {
                HStack {
                    Text(item.title)
                        .font(TallyType.body(15, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)

                    Text("\(TallyLocalization.format(.entryCount, locale: LanguageManager.shared.currentLocale, item.count)) · \(Int(round(item.percent * 100)))%")
                        .font(TallyType.body(11, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)

                    Spacer()

                    Text(MoneyFormatter.wholeYuanString(fromCents: item.amountCents, locale: LanguageManager.shared.currentLocale))
                        .font(TallyType.num(15, weight: .semibold))
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
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(TallyLocalization.text(.detail, locale: LanguageManager.shared.currentLocale))
                Spacer()
                Text(TallyLocalization.text(.detailByDate, locale: LanguageManager.shared.currentLocale))
                    .font(TallyType.body(12, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
            }
            .padding(.horizontal, BillsListLayout.horizontalPadding)

            if dayKeys.isEmpty {
                Text(TallyLocalization.text(.noDetails, locale: LanguageManager.shared.currentLocale))
                    .font(TallyType.body(13, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .padding(.horizontal, BillsListLayout.horizontalPadding)
                    .padding(.top, TallySpacing.s3)
            } else {
                VStack(spacing: TallySpacing.s4) {
                    ForEach(dayKeys, id: \.self) { dayKey in
                        let rows = groupedRows[dayKey] ?? []
                        VStack(alignment: .leading, spacing: TallySpacing.s2) {
                            Text(dayTitle(for: dayKey))
                                .font(TallyType.body(13, weight: .semibold))
                                .foregroundStyle(Color.tallyInkDim)
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
                        }
                    }
                }
            }
        }
    }

    private func dayTitle(for dayKey: String) -> String {
        guard let date = DayKeyFormatter.date(from: dayKey, timeZone: .autoupdatingCurrent) else {
            return dayKey
        }
        let locale = LanguageManager.shared.currentLocale
        return "\(TallyLocalization.monthDayTitle(for: date, locale: locale)) \(TallyLocalization.weekdayTitle(for: date, locale: locale))"
    }
}

private struct DenseBillRow: View {
    let item: BillsListViewModel.RowItem

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        HStack(spacing: TallySpacing.s3) {
            CategoryTile(iconName: item.iconName, color: iconColor, size: 36, radius: TallyRadii.md)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(TallyType.body(13, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(TallyType.body(10, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TallyAmountText(
                cents: item.amountCents,
                sign: item.isIncome ? .income : .expense,
                size: 14,
                weight: .semibold,
                color: item.isIncome ? themeColors.accent : .tallyInk
            )
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, BillsListLayout.horizontalPadding)
        .padding(.vertical, TallySpacing.s1 + 1)
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
        let locale = LanguageManager.shared.currentLocale
        let typeText = item.isIncome
            ? TallyLocalization.text(.income, locale: locale)
            : TallyLocalization.text(.expense, locale: locale)
        let amountText = MoneyFormatter.string(fromCents: item.amountCents, locale: locale)
        return "\(item.title)，\(item.subtitle)，\(typeText)，\(amountText)"
    }
}

private struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(TallyType.body(15, weight: .semibold))
            .foregroundStyle(Color.tallyInkDim)
    }
}

private struct DenseBillRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.tallySurface2 : Color.clear)
            .animation(.tallyFast, value: configuration.isPressed)
    }
}

#if DEBUG
#Preview("BillsList") {
    let sample = BillsListViewModel.makeMockData(anchor: BillsListViewModel.mockAnchorDate)
    NavigationStack {
        BillsListView(
            repository: MockBillRepository(seed: sample.bills),
            categoryRepository: MockCategoryRepository(seed: sample.categories),
            suggestionService: StubCategorySuggestionService()
        )
    }
    .preferredColorScheme(.dark)
}
#endif
