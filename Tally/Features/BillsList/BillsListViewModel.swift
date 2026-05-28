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

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private var categoriesById: [UUID: CategoryRecord] = [:]
    private var currentBills: [BillRecord] = []
    private var currentBillsById: [UUID: BillRecord] = [:]
    private var didLoad = false
    private var isBatchingFilterUpdates = false

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    init(repository: BillRepository, categoryRepository: CategoryRepository) {
        self.billRepository = repository
        self.categoryRepository = categoryRepository
    }

    var timeTitle: String {
        let normalized = normalizedAnchorDate
        switch timeRange {
        case .week:
            let year = calendar.component(.yearForWeekOfYear, from: normalized)
            let week = calendar.component(.weekOfYear, from: normalized)
            return "\(year) 年第 \(week) 周"
        case .month:
            let year = calendar.component(.year, from: normalized)
            let month = calendar.component(.month, from: normalized)
            return "\(year) · \(month) 月"
        case .quarter:
            let year = calendar.component(.year, from: normalized)
            let quarter = ((calendar.component(.month, from: normalized) - 1) / 3) + 1
            return "\(year) · Q\(quarter)"
        case .year:
            let year = calendar.component(.year, from: normalized)
            return "\(year) · 全年"
        case .custom:
            let range = dayKeyRange(for: normalized)
            return "\(range.start) 至 \(range.end)"
        }
    }

    var summaryTitle: String {
        let typeTitle = selectedType == .expense ? "支出" : "收入"
        return "\(timeRange.summaryPrefix)总\(typeTitle)"
    }

    var rankTitle: String {
        selectedType == .expense ? "支出排行" : "收入排行"
    }

    var trend30Cents: [Int] {
        trendValuesCents
    }

    var categoryRanking: [RankingItem] {
        rankingItems
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
            errorMessage = FeatureErrorMessage.message(for: error, fallback: "账本加载失败，请稍后重试")
        }
    }

    private var normalizedAnchorDate: Date {
        let dayKey = DayKeyFormatter.dayKey(for: anchorDate)
        return DayKeyFormatter.date(from: dayKey, timeZone: calendar.timeZone) ?? anchorDate
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
                calendar: calendar
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
            errorMessage = FeatureErrorMessage.message(for: error, fallback: "账本加载失败，请稍后重试")
        }
    }

    private func updateAvailableYears() {
        do {
            let years = try billRepository.listYears()
            let currentYear = calendar.component(.year, from: Date())
            let uniqueYears = Array(Set(years + [currentYear])).sorted()
            availableYears = uniqueYears.isEmpty ? [currentYear] : uniqueYears
        } catch {
            let currentYear = calendar.component(.year, from: Date())
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
        let title = categoriesById[categoryId]?.name ?? "未分类"
        let detailItems = items.map { bill in
            let note = bill.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let noteText = note.isEmpty ? "无备注" : note
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
            totalCents: totalCents,
            isIncome: selectedType == .income,
            items: detailItems
        )
    }

    private func dayKeyRange(for anchor: Date) -> (start: String, end: String) {
        let interval: DateInterval
        switch timeRange {
        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: anchor) ?? DateInterval(start: anchor, end: anchor)
        case .month:
            interval = calendar.dateInterval(of: .month, for: anchor) ?? DateInterval(start: anchor, end: anchor)
        case .quarter:
            let month = calendar.component(.month, from: anchor)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: anchor)
            components.month = quarterStartMonth
            components.day = 1
            let start = calendar.date(from: components) ?? anchor
            let end = calendar.date(byAdding: .month, value: 3, to: start) ?? start
            interval = DateInterval(start: start, end: end)
        case .year:
            interval = calendar.dateInterval(of: .year, for: anchor) ?? DateInterval(start: anchor, end: anchor)
        case .custom:
            let start = calendar.date(byAdding: .day, value: -29, to: anchor) ?? anchor
            let end = calendar.date(byAdding: .day, value: 1, to: anchor) ?? anchor
            interval = DateInterval(start: start, end: end)
        }

        let endDate = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
        let startKey = DayKeyFormatter.dayKey(for: interval.start, timeZone: calendar.timeZone)
        let endKey = DayKeyFormatter.dayKey(for: endDate, timeZone: calendar.timeZone)
        return (startKey, endKey)
    }

    private func computeSummaryChange(currentTotal: Int) -> SummaryChange? {
        let previousAnchor: Date
        switch timeRange {
        case .week:
            previousAnchor = calendar.date(byAdding: .weekOfYear, value: -1, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .month:
            previousAnchor = calendar.date(byAdding: .month, value: -1, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .quarter:
            previousAnchor = calendar.date(byAdding: .month, value: -3, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .year:
            previousAnchor = calendar.date(byAdding: .year, value: -1, to: normalizedAnchorDate) ?? normalizedAnchorDate
        case .custom:
            previousAnchor = calendar.date(byAdding: .day, value: -30, to: normalizedAnchorDate) ?? normalizedAnchorDate
        }

        let previousRange = dayKeyRange(for: previousAnchor)
        let previousTotal = (try? billRepository.list(
            fromDayKey: previousRange.start,
            toDayKey: previousRange.end,
            type: selectedType
        ))?.reduce(0) { $0 + $1.amount.cents } ?? 0
        guard previousTotal > 0 else { return nil }

        let delta = Double(currentTotal - previousTotal) / Double(previousTotal)
        let percent = abs(delta) * 100
        let percentText = String(format: "%.0f%%", percent)
        return SummaryChange(percentText: percentText, isPositive: delta >= 0)
    }

    private func makeRowItem(for bill: BillRecord) -> RowItem {
        let categoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
        let category = categoriesById[categoryId]
        let title = category?.name ?? "未分类"
        let iconName = category?.iconKey ?? "tag"
        let iconHex = category?.colorHex.map { UInt32($0) }

        let timeString = BillTimeFormatter.timeText(for: bill)
        let note = bill.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let subtitle = note.isEmpty ? timeString : "\(timeString) · \(note)"

        return RowItem(
            id: bill.id,
            title: title,
            subtitle: subtitle,
            iconName: iconName,
            iconColorHex: iconHex,
            amountCents: bill.amount.cents,
            isIncome: bill.type == .income
        )
    }

    private static func detailDateString(for bill: BillRecord) -> String {
        guard let date = DayKeyFormatter.date(from: bill.occurredLocalDate, timeZone: .autoupdatingCurrent) else {
            return bill.occurredLocalDate
        }
        return detailDateFormatter.string(from: date)
    }
}
