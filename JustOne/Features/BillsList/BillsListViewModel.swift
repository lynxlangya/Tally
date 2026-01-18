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

    @Published var selectedType: BillType = .expense {
        didSet { applyFilters() }
    }

    @Published var timeRange: TimeRange = .month {
        didSet { applyFilters() }
    }

    @Published var rankSort: RankSort = .most {
        didSet { applyFilters() }
    }

    @Published var anchorDate: Date = Date() {
        didSet { applyFilters() }
    }

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private var allBills: [BillRecord] = []
    private var categoriesById: [UUID: CategoryRecord] = [:]

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter
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
        let year = calendar.component(.year, from: normalized)
        switch timeRange {
        case .week:
            let week = calendar.component(.weekOfYear, from: normalized)
            return "\(year) 年第 \(week) 周"
        case .month:
            let month = calendar.component(.month, from: normalized)
            return "\(year) 年 \(month) 月"
        case .year:
            return "\(year) 年"
        }
    }

    var summaryTitle: String {
        let typeTitle = selectedType == .expense ? "支出" : "收入"
        return "\(timeRange.summaryPrefix)总\(typeTitle)"
    }

    var rankTitle: String {
        selectedType == .expense ? "支出排行" : "收入排行"
    }

    func toggleRankSort() {
        rankSort = rankSort == .most ? .least : .most
    }

    func load() {
        do {
            let bills = try billRepository.list()
            let expenseCategories = try categoryRepository.list(type: .expense)
            let incomeCategories = try categoryRepository.list(type: .income)
            let categories = expenseCategories + incomeCategories
            allBills = bills
            categoriesById = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
            errorMessage = nil
            applyFilters()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private var normalizedAnchorDate: Date {
        let dayKey = DayKeyFormatter.dayKey(for: anchorDate)
        return DayKeyFormatter.date(from: dayKey, timeZone: calendar.timeZone) ?? anchorDate
    }

    private func applyFilters() {
        let filtered = filteredBills(for: normalizedAnchorDate)
        summaryTotalCents = filtered.reduce(0) { $0 + $1.amount.cents }
        summaryChange = computeSummaryChange(currentTotal: summaryTotalCents)

        let trend = buildTrend(for: filtered)
        trendPoints = trend.points
        trendHighlightIndex = trend.highlightIndex
        axisLabels = trend.axisLabels
        trendValuesCents = trend.valuesCents

        rankingItems = buildRanking(for: filtered)

        let grouped = Dictionary(grouping: filtered, by: { $0.occurredLocalDate })
        groupedRows = grouped.mapValues { bills in
            bills.sorted { $0.occurredAtUTC > $1.occurredAtUTC }
                .map { makeRowItem(for: $0) }
        }
        dayKeys = groupedRows.keys.sorted(by: >)
    }

    private func filteredBills(for anchor: Date) -> [BillRecord] {
        allBills.filter { bill in
            bill.deletedAt == nil
                && bill.type == selectedType
                && isInSelectedRange(dayKey: bill.occurredLocalDate, anchor: anchor)
        }
    }

    func billRecord(for id: UUID) -> BillRecord? {
        allBills.first { $0.id == id }
    }

    func categoryDetail(for categoryId: UUID) -> CategoryDetail {
        let filtered = filteredBills(for: normalizedAnchorDate)
        let items = filtered
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

    private func isInSelectedRange(dayKey: String, anchor: Date) -> Bool {
        guard let date = DayKeyFormatter.date(from: dayKey, timeZone: calendar.timeZone) else { return false }
        switch timeRange {
        case .week:
            return calendar.component(.weekOfYear, from: date) == calendar.component(.weekOfYear, from: anchor)
                && calendar.component(.yearForWeekOfYear, from: date) == calendar.component(.yearForWeekOfYear, from: anchor)
        case .month:
            return calendar.component(.year, from: date) == calendar.component(.year, from: anchor)
                && calendar.component(.month, from: date) == calendar.component(.month, from: anchor)
        case .year:
            return calendar.component(.year, from: date) == calendar.component(.year, from: anchor)
        }
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
        }

        let previousTotal = filteredBills(for: previousAnchor).reduce(0) { $0 + $1.amount.cents }
        guard previousTotal > 0 else { return nil }

        let delta = Double(currentTotal - previousTotal) / Double(previousTotal)
        let percent = abs(delta) * 100
        let percentText = String(format: "%.0f%%", percent)
        return SummaryChange(percentText: percentText, isPositive: delta >= 0)
    }

    private func buildTrend(for bills: [BillRecord]) -> (points: [Double], highlightIndex: Int?, axisLabels: [String], valuesCents: [Int]) {
        let totals: [Int]
        let axisLabels: [String]

        switch timeRange {
        case .week:
            let start = startOfWeek(for: normalizedAnchorDate)
            totals = (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
                let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
                return bills.filter { $0.occurredLocalDate == dayKey }.reduce(0) { $0 + $1.amount.cents }
            }
            axisLabels = ["一", "二", "三", "四", "五", "六", "日"]
        case .month:
            let start = startOfMonth(for: normalizedAnchorDate)
            let dayRange = calendar.range(of: .day, in: .month, for: start) ?? 1..<2
            totals = dayRange.map { day in
                let date = calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
                let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
                return bills.filter { $0.occurredLocalDate == dayKey }.reduce(0) { $0 + $1.amount.cents }
            }
            let month = calendar.component(.month, from: normalizedAnchorDate)
            let lastDay = dayRange.count
            axisLabels = ["\(month)月1日", "15日", "\(lastDay)日"]
        case .year:
            let year = calendar.component(.year, from: normalizedAnchorDate)
            totals = (1...12).map { month in
                let prefix = String(format: "%04d-%02d", year, month)
                return bills.filter { $0.occurredLocalDate.hasPrefix(prefix) }.reduce(0) { $0 + $1.amount.cents }
            }
            axisLabels = ["1月", "6月", "12月"]
        }

        let maxValue = totals.max() ?? 0
        let normalized = maxValue > 0 ? totals.map { Double($0) / Double(maxValue) } : totals.map { _ in 0 }
        let highlightIndex = totals.firstIndex(of: maxValue)
        return (normalized, highlightIndex, axisLabels, totals)
    }

    private func buildRanking(for bills: [BillRecord]) -> [RankingItem] {
        let totalCents = bills.reduce(0) { $0 + $1.amount.cents }
        guard totalCents > 0 else { return [] }

        let totals = bills.reduce(into: [UUID: Int]()) { result, bill in
            let categoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
            result[categoryId, default: 0] += bill.amount.cents
        }

        let sorted = totals.filter { $0.value > 0 }.sorted { lhs, rhs in
            if rankSort == .most {
                return lhs.value > rhs.value
            }
            return lhs.value < rhs.value
        }

        return sorted.prefix(5).map { (id, cents) in
            let name = categoriesById[id]?.name ?? "未分类"
            let percent = Double(cents) / Double(totalCents)
            return RankingItem(id: id, title: name, percent: percent, amountCents: cents)
        }
    }

    private func makeRowItem(for bill: BillRecord) -> RowItem {
        let categoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
        let category = categoriesById[categoryId]
        let title = category?.name ?? "未分类"
        let iconName = category?.iconKey ?? "questionmark"
        let iconHex = category?.colorHex.flatMap { UInt32($0) }

        let timeString = Self.timeFormatterString(for: bill)
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

    private func startOfWeek(for date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    private func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private static func timeFormatterString(for bill: BillRecord) -> String {
        let formatter = timeFormatter
        let timeZone = TimeZone(identifier: bill.tzId)
            ?? TimeZone(secondsFromGMT: bill.tzOffset)
            ?? .current
        formatter.timeZone = timeZone
        return formatter.string(from: bill.occurredAtUTC)
    }

    private static func detailDateString(for bill: BillRecord) -> String {
        guard let date = DayKeyFormatter.date(from: bill.occurredLocalDate, timeZone: .autoupdatingCurrent) else {
            return bill.occurredLocalDate
        }
        return detailDateFormatter.string(from: date)
    }
}
