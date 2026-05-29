import Foundation
import Combine

@MainActor
final class BillsListViewModel: ObservableObject {
    @Published private(set) var groupedRows: [String: [RowItem]] = [:]
    @Published private(set) var dayKeys: [String] = []
    @Published private(set) var summaryTotalCents: Int = 0
    @Published private(set) var summaryChange: SummaryChange?
    @Published private(set) var trendPoints: [Double] = []
    @Published private(set) var trendHighlightIndex: Int?
    @Published private(set) var axisLabels: [String] = []
    @Published private(set) var trendValuesCents: [Int] = []
    @Published private(set) var rankingItems: [RankingItem] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var availableYears: [Int] = []
    @Published private(set) var summary: Summary = Summary(expenseCents: 0, incomeCents: 0)
    @Published private(set) var trendPeak: TrendPeak?
    @Published private(set) var selectedRangeBills: [BillRecord] = []
    @Published private(set) var categoryRankingTotalCount: Int = 0

    @Published var selectedType: BillType = .expense {
        didSet {
            guard oldValue != selectedType else { return }
            applyFiltersIfReady()
        }
    }

    @Published var timeRange: TimeRange = .month {
        didSet {
            guard oldValue != timeRange else { return }
            applyFiltersIfReady()
        }
    }

    @Published var rankSort: RankSort = .most {
        didSet {
            guard oldValue != rankSort else { return }
            applyFiltersIfReady()
        }
    }

    @Published var anchorDate: Date = Date() {
        didSet {
            guard oldValue != anchorDate else { return }
            applyFiltersIfReady()
        }
    }

    @Published var customStart: Date {
        didSet {
            guard oldValue != customStart else { return }
            applyFiltersIfReady()
        }
    }

    @Published var customEnd: Date {
        didSet {
            guard oldValue != customEnd else { return }
            applyFiltersIfReady()
        }
    }

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private var categoriesById: [UUID: CategoryRecord] = [:]
    private var currentBills: [BillRecord] = []
    private var currentBillsById: [UUID: BillRecord] = [:]
    private var didLoad = false
    private var isBatchingFilterUpdates = false
    private let nowProvider: () -> Date

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    init(
        repository: BillRepository,
        categoryRepository: CategoryRepository,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.billRepository = repository
        self.categoryRepository = categoryRepository
        self.nowProvider = nowProvider
        let today = nowProvider()
        self.customEnd = today
        self.customStart = Calendar.current.date(byAdding: .day, value: -29, to: today) ?? today
    }

    var timeTitle: String {
        let normalized = normalizedAnchorDate
        let locale = LanguageManager.shared.currentLocale
        switch timeRange {
        case .week:
            let range = dateRange(for: normalized)
            return "\(shortDateTitle(for: range.start, locale: locale))–\(shortDateTitle(for: range.end, locale: locale))"
        case .month:
            return TallyLocalization.monthYearTitle(for: normalized, locale: locale)
        case .year:
            return TallyLocalization.yearTitle(for: normalized, locale: locale)
        case .custom:
            let range = dateRange(for: normalized)
            return "\(shortDateTitle(for: range.start, locale: locale))–\(shortDateTitle(for: range.end, locale: locale))"
        }
    }

    var periodNavigationTitle: String {
        let normalized = normalizedAnchorDate
        let locale = LanguageManager.shared.currentLocale
        switch timeRange {
        case .week:
            let range = dateRange(for: normalized)
            return "\(shortDateTitle(for: range.start, locale: locale)) – \(shortDateTitle(for: range.end, locale: locale))"
        case .month:
            return TallyLocalization.monthYearTitle(for: normalized, locale: locale)
        case .year:
            return TallyLocalization.yearTitle(for: normalized, locale: locale)
        case .custom:
            let range = dateRange(for: normalized)
            return "\(shortDateTitle(for: range.start, locale: locale)) – \(shortDateTitle(for: range.end, locale: locale))"
        }
    }

    var periodEyebrow: String {
        let normalized = normalizedAnchorDate
        let locale = LanguageManager.shared.currentLocale
        switch timeRange {
        case .week:
            let weekStart = dateRange(for: normalized).start
            return TallyLocalization.format(
                .periodWeekOrdinal,
                locale: locale,
                TallyLocalization.monthTitle(for: weekStart, locale: locale),
                weekOrdinalInMonth(for: weekStart)
            )
        case .month:
            return TallyLocalization.monthTitle(for: normalized, locale: locale)
        case .year:
            return TallyLocalization.yearTitle(for: normalized, locale: locale)
        case .custom:
            return TallyLocalization.text(.timeRangeCustom, locale: locale)
        }
    }

    var summaryTitle: String {
        let typeTitle = selectedTypeTitle
        return TallyLocalization.format(
            "summary_total_type",
            locale: LanguageManager.shared.currentLocale,
            timeRange.summaryPrefix,
            typeTitle
        )
    }

    var selectedTypeTitle: String {
        selectedType == .expense
            ? TallyLocalization.text(.expense, locale: LanguageManager.shared.currentLocale)
            : TallyLocalization.text(.income, locale: LanguageManager.shared.currentLocale)
    }

    var selectedTotalCents: Int {
        selectedType == .expense ? summary.expenseCents : summary.incomeCents
    }

    var rankTitle: String {
        TallyLocalization.text(selectedType == .expense ? "expense_ranking" : "income_ranking", locale: LanguageManager.shared.currentLocale)
    }

    var trend30Cents: [Int] {
        trendValuesCents
    }

    var categoryRanking: [RankingItem] {
        rankingItems
    }

    var trendTitle: String {
        let typeTitle = selectedTypeTitle
        switch timeRange {
        case .week:
            return TallyLocalization.format(.trendWeek, locale: LanguageManager.shared.currentLocale, typeTitle)
        case .month:
            return TallyLocalization.format(.trendMonth, locale: LanguageManager.shared.currentLocale, typeTitle)
        case .year:
            return TallyLocalization.format(.trendYear, locale: LanguageManager.shared.currentLocale, typeTitle)
        case .custom:
            return TallyLocalization.format(.trendCustom, locale: LanguageManager.shared.currentLocale, typeTitle)
        }
    }

    var canGoNext: Bool {
        guard timeRange != .custom else { return false }

        return periodStart(for: normalizedAnchorDate) < periodStart(for: normalizedDate(nowProvider()))
    }

    var latestSelectableDate: Date {
        normalizedDate(nowProvider())
    }

    func toggleRankSort() {
        updateFilters(rankSort: rankSort == .most ? .least : .most)
    }

    func updateFilters(
        selectedType: BillType? = nil,
        timeRange: TimeRange? = nil,
        rankSort: RankSort? = nil,
        anchorDate: Date? = nil
    ) {
        var shouldApply = false
        isBatchingFilterUpdates = true
        defer {
            isBatchingFilterUpdates = false
            if shouldApply {
                applyFiltersIfReady()
            }
        }

        if let selectedType, self.selectedType != selectedType {
            self.selectedType = selectedType
            shouldApply = true
        }
        if let timeRange, self.timeRange != timeRange {
            self.timeRange = timeRange
            shouldApply = true
        }
        if let rankSort, self.rankSort != rankSort {
            self.rankSort = rankSort
            shouldApply = true
        }
        if let anchorDate, self.anchorDate != anchorDate {
            self.anchorDate = anchorDate
            shouldApply = true
        }
    }

    func goPrevious() {
        guard timeRange != .custom else { return }
        updateFilters(anchorDate: shiftedAnchor(by: -1))
    }

    func goNext() {
        guard canGoNext else { return }
        let nextAnchor = shiftedAnchor(by: 1)
        updateFilters(anchorDate: min(nextAnchor, normalizedDate(nowProvider())))
    }

    func jump(to date: Date) {
        updateFilters(anchorDate: normalizedDate(date))
    }

    func updateCustomRange(start: Date, end: Date) {
        let today = normalizedDate(nowProvider())
        let normalizedStart = min(normalizedDate(start), today)
        let normalizedEnd = min(normalizedDate(end), today)
        let lower = min(normalizedStart, normalizedEnd)
        let upper = max(normalizedStart, normalizedEnd)

        var shouldApply = false
        isBatchingFilterUpdates = true
        defer {
            isBatchingFilterUpdates = false
            if shouldApply {
                applyFiltersIfReady()
            }
        }

        if customStart != lower {
            customStart = lower
            shouldApply = true
        }
        if customEnd != upper {
            customEnd = upper
            shouldApply = true
        }
        if anchorDate != upper {
            anchorDate = upper
            shouldApply = true
        }
    }

    func load() {
        do {
            let expenseCategories = try categoryRepository.list(type: .expense)
            let incomeCategories = try categoryRepository.list(type: .income)
            let categories = expenseCategories + incomeCategories
            categoriesById = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
            errorMessage = nil
            updateAvailableYears()
            didLoad = true
            applyFilters()
        } catch {
            didLoad = false
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text(.billLoadFailed, locale: LanguageManager.shared.currentLocale)
            )
        }
    }

    private var normalizedAnchorDate: Date {
        normalizedDate(anchorDate)
    }

    private func normalizedDate(_ date: Date) -> Date {
        let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
        return DayKeyFormatter.date(from: dayKey, timeZone: calendar.timeZone) ?? date
    }

    private func applyFiltersIfReady() {
        guard didLoad, !isBatchingFilterUpdates else { return }
        applyFilters()
    }

    private func applyFilters() {
        let range = dayKeyRange(for: normalizedAnchorDate)
        do {
            let allBills = try billRepository.list(
                fromDayKey: range.start,
                toDayKey: range.end,
                type: nil
            )
            let filtered = allBills.filter { $0.type == selectedType }
            selectedRangeBills = allBills

            summary = Summary(
                expenseCents: allBills.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount.cents },
                incomeCents: allBills.filter { $0.type == .income }.reduce(0) { $0 + $1.amount.cents }
            )

            currentBills = filtered
            currentBillsById = Dictionary(uniqueKeysWithValues: allBills.map { ($0.id, $0) })

            summaryTotalCents = filtered.reduce(0) { $0 + $1.amount.cents }
            summaryChange = computeSummaryChange(currentTotal: summaryTotalCents)

            let trendBills = allBills.filter { $0.type == .expense }
            let trend = BillsListTrendBuilder(
                timeRange: timeRange,
                anchorDate: normalizedAnchorDate,
                customStart: normalizedCustomRange.start,
                customEnd: normalizedCustomRange.end,
                calendar: calendar,
                locale: LanguageManager.shared.currentLocale
            )
            .build(for: trendBills)
            trendPoints = trend.points
            trendHighlightIndex = trend.highlightIndex
            axisLabels = trend.axisLabels
            trendValuesCents = trend.valuesCents
            trendPeak = trend.peak

            let rankingBuilder = BillsListRankingBuilder(
                sort: rankSort,
                categoriesById: categoriesById
            )
            rankingItems = rankingBuilder.build(for: filtered)
            categoryRankingTotalCount = rankingBuilder.categoryCount(for: filtered)

            let grouped = Dictionary(grouping: allBills, by: { $0.occurredLocalDate })
            groupedRows = grouped.mapValues { bills in
                bills.sorted { $0.occurredAtUTC > $1.occurredAtUTC }
                    .map { makeRowItem(for: $0) }
            }
            dayKeys = groupedRows.keys.sorted(by: >)
            errorMessage = nil
        } catch {
            selectedRangeBills = []
            currentBills = []
            currentBillsById = [:]
            groupedRows = [:]
            dayKeys = []
            rankingItems = []
            trendPoints = []
            trendHighlightIndex = nil
            axisLabels = []
            trendValuesCents = []
            trendPeak = nil
            summary = Summary(expenseCents: 0, incomeCents: 0)
            categoryRankingTotalCount = 0
            summaryTotalCents = 0
            summaryChange = nil
            errorMessage = FeatureErrorMessage.message(
                for: error,
                fallback: TallyLocalization.text(.billLoadFailed, locale: LanguageManager.shared.currentLocale)
            )
        }
    }

    private func updateAvailableYears() {
        do {
            let years = try billRepository.listYears()
            let currentYear = calendar.component(.year, from: nowProvider())
            let uniqueYears = Array(Set(years + [currentYear])).sorted()
            availableYears = uniqueYears.isEmpty ? [currentYear] : uniqueYears
        } catch {
            let currentYear = calendar.component(.year, from: nowProvider())
            availableYears = [currentYear]
        }
    }

    func billRecord(for id: UUID) -> BillRecord? {
        currentBillsById[id]
    }

    func categoryDetail(for categoryId: UUID) -> CategoryDetail {
        let items = currentBills
            .filter { bill in
                let billCategoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
                return billCategoryId == categoryId
            }
            .sorted { $0.occurredAtUTC > $1.occurredAtUTC }

        let totalCents = items.reduce(0) { $0 + $1.amount.cents }
        let category = categoriesById[categoryId]
        let title = category?.name ?? TallyLocalization.text(.uncategorized, locale: LanguageManager.shared.currentLocale)
        let detailItems = items.map { bill in
            let note = bill.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let noteText = note.isEmpty ? TallyLocalization.text(.noNote, locale: LanguageManager.shared.currentLocale) : note
            return CategoryDetailItem(
                id: bill.id,
                dateText: Self.detailDateString(for: bill),
                noteText: noteText,
                amountCents: bill.amount.cents
            )
        }

        return CategoryDetail(
            id: categoryId,
            title: title,
            iconName: categoryIconName(for: category),
            iconColorHex: categoryIconHex(for: category),
            totalCents: totalCents,
            isIncome: selectedType == .income,
            items: detailItems
        )
    }

    private func dayKeyRange(for anchor: Date) -> (start: String, end: String) {
        let range = dateRange(for: anchor)
        let startKey = DayKeyFormatter.dayKey(for: range.start, timeZone: calendar.timeZone)
        let endKey = DayKeyFormatter.dayKey(for: range.end, timeZone: calendar.timeZone)
        return (startKey, endKey)
    }

    private var normalizedCustomRange: (start: Date, end: Date) {
        let today = normalizedDate(nowProvider())
        let start = min(normalizedDate(customStart), today)
        let end = min(normalizedDate(customEnd), today)
        return start <= end ? (start, end) : (end, start)
    }

    private func dateRange(for anchor: Date) -> (start: Date, end: Date) {
        let interval: DateInterval
        switch timeRange {
        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: anchor) ?? DateInterval(start: anchor, end: anchor)
        case .month:
            interval = calendar.dateInterval(of: .month, for: anchor) ?? DateInterval(start: anchor, end: anchor)
        case .year:
            interval = calendar.dateInterval(of: .year, for: anchor) ?? DateInterval(start: anchor, end: anchor)
        case .custom:
            return normalizedCustomRange
        }

        let endDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        return (interval.start, endDate)
    }

    private func computeSummaryChange(currentTotal: Int) -> SummaryChange? {
        let previousAnchor: Date
        switch timeRange {
        case .week:
            previousAnchor = calendar.date(byAdding: .weekOfYear, value: -1, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .month:
            previousAnchor = calendar.date(byAdding: .month, value: -1, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .year:
            previousAnchor = calendar.date(byAdding: .year, value: -1, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .custom:
            let range = normalizedCustomRange
            let dayCount = max((calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 0) + 1, 1)
            let previousEnd = calendar.date(byAdding: .day, value: -1, to: range.start) ?? range.start
            let previousStart = calendar.date(byAdding: .day, value: -(dayCount - 1), to: previousEnd) ?? previousEnd
            let previousStartKey = DayKeyFormatter.dayKey(for: previousStart, timeZone: calendar.timeZone)
            let previousEndKey = DayKeyFormatter.dayKey(for: previousEnd, timeZone: calendar.timeZone)
            let previousTotal = (try? billRepository.list(
                fromDayKey: previousStartKey,
                toDayKey: previousEndKey,
                type: selectedType
            ))?.reduce(0) { $0 + $1.amount.cents } ?? 0
            return makeSummaryChange(currentTotal: currentTotal, previousTotal: previousTotal)
        }

        let previousRange = dayKeyRange(for: previousAnchor)
        let previousTotal = (try? billRepository.list(
            fromDayKey: previousRange.start,
            toDayKey: previousRange.end,
            type: selectedType
        ))?.reduce(0) { $0 + $1.amount.cents } ?? 0
        return makeSummaryChange(currentTotal: currentTotal, previousTotal: previousTotal)
    }

    private func makeSummaryChange(currentTotal: Int, previousTotal: Int) -> SummaryChange? {
        guard previousTotal > 0 else { return nil }

        let delta = Double(currentTotal - previousTotal) / Double(previousTotal)
        let percent = abs(delta) * 100
        let percentText = String(format: "%.0f%%", percent)
        return SummaryChange(percentText: percentText, isPositive: delta >= 0)
    }

    private func shiftedAnchor(by value: Int) -> Date {
        switch timeRange {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: value, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .month:
            return calendar.date(byAdding: .month, value: value, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .year:
            return calendar.date(byAdding: .year, value: value, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .custom:
            return normalizedAnchorDate
        }
    }

    private func periodStart(for date: Date) -> Date {
        switch timeRange {
        case .week:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            return calendar.date(from: components) ?? date
        case .month:
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? date
        case .year:
            let components = calendar.dateComponents([.year], from: date)
            return calendar.date(from: components) ?? date
        case .custom:
            return normalizedCustomRange.start
        }
    }

    private func shortDateTitle(for date: Date, locale: Locale) -> String {
        TallyLocalization.monthDayTitle(for: date, locale: locale)
    }

    private func weekOrdinalInMonth(for weekStart: Date) -> Int {
        let month = calendar.component(.month, from: weekStart)
        let year = calendar.component(.year, from: weekStart)
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return 1
        }
        let firstWeekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start ?? monthStart
        let firstWeekOverlapsMonth = calendar.component(.month, from: firstWeekStart) == month
        let normalizedFirstWeekStart = firstWeekOverlapsMonth
            ? firstWeekStart
            : (calendar.date(byAdding: .weekOfYear, value: 1, to: firstWeekStart) ?? firstWeekStart)
        let offset = calendar.dateComponents([.weekOfYear], from: normalizedFirstWeekStart, to: weekStart).weekOfYear ?? 0
        return max(offset + 1, 1)
    }

    private func makeRowItem(for bill: BillRecord) -> RowItem {
        let categoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
        let category = categoriesById[categoryId]
        let title = category?.name ?? TallyLocalization.text(.uncategorized, locale: LanguageManager.shared.currentLocale)

        let timeString = BillTimeFormatter.timeText(for: bill)
        let note = bill.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let subtitle = note.isEmpty ? timeString : "\(timeString) · \(note)"

        return RowItem(
            id: bill.id,
            title: title,
            subtitle: subtitle,
            iconName: categoryIconName(for: category),
            iconColorHex: categoryIconHex(for: category),
            amountCents: bill.amount.cents,
            isIncome: bill.type == .income
        )
    }

    private func categoryIconName(for category: CategoryRecord?) -> String {
        category?.iconKey ?? "tag"
    }

    private func categoryIconHex(for category: CategoryRecord?) -> UInt32? {
        category?.colorHex.map { UInt32($0) }
    }

    private static func detailDateString(for bill: BillRecord) -> String {
        guard let date = DayKeyFormatter.date(from: bill.occurredLocalDate, timeZone: .autoupdatingCurrent) else {
            return bill.occurredLocalDate
        }
        return TallyLocalization.monthDayTitle(for: date, locale: LanguageManager.shared.currentLocale)
    }
}
