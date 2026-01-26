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
    private var categoriesById: [UUID: CategoryRecord] = [:]
    private var currentBills: [BillRecord] = []
    private var currentBillsById: [UUID: BillRecord] = [:]

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
        switch timeRange {
        case .week:
            let year = calendar.component(.yearForWeekOfYear, from: normalized)
            let week = calendar.component(.weekOfYear, from: normalized)
            return "\(year) 年第 \(week) 周"
        case .month:
            let year = calendar.component(.year, from: normalized)
            let month = calendar.component(.month, from: normalized)
            return "\(year) 年 \(month) 月"
        case .year:
            let year = calendar.component(.year, from: normalized)
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
            let expenseCategories = try categoryRepository.list(type: .expense)
            let incomeCategories = try categoryRepository.list(type: .income)
            let categories = expenseCategories + incomeCategories
            categoriesById = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
            errorMessage = nil
            updateAvailableYears()
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
        let range = dayKeyRange(for: normalizedAnchorDate)
        do {
            let filtered = try billRepository.list(
                fromDayKey: range.start,
                toDayKey: range.end,
                type: selectedType
            )
            currentBills = filtered
            currentBillsById = Dictionary(uniqueKeysWithValues: filtered.map { ($0.id, $0) })

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
            errorMessage = nil
        } catch {
            currentBills = []
            currentBillsById = [:]
            groupedRows = [:]
            dayKeys = []
            rankingItems = []
            trendPoints = []
            trendHighlightIndex = nil
            axisLabels = []
            trendValuesCents = []
            summaryTotalCents = 0
            summaryChange = nil
            errorMessage = String(describing: error)
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
        case .year:
            interval = calendar.dateInterval(of: .year, for: anchor) ?? DateInterval(start: anchor, end: anchor)
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
        case .year:
            previousAnchor = calendar.date(byAdding: .year, value: -1, to: normalizedAnchorDate) ?? normalizedAnchorDate
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
