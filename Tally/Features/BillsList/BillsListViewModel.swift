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
            let trend = buildTrend(for: trendBills)
            trendPoints = trend.points
            trendHighlightIndex = trend.highlightIndex
            axisLabels = trend.axisLabels
            trendValuesCents = trend.valuesCents
            trendPeak = makeTrendPeak(values: trend.valuesCents, labels: trend.pointLabels)

            rankingItems = buildRanking(for: filtered)
            categoryRankingTotalCount = categoryCount(for: filtered)

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

    private func buildTrend(for bills: [BillRecord]) -> (points: [Double], highlightIndex: Int?, axisLabels: [String], valuesCents: [Int], pointLabels: [String]) {
        let totals: [Int]
        let axisLabels: [String]
        let pointLabels: [String]
        let dayTotals = bills.reduce(into: [String: Int]()) { result, bill in
            result[bill.occurredLocalDate, default: 0] += bill.amount.cents
        }
        let monthTotals = bills.reduce(into: [String: Int]()) { result, bill in
            let monthKey = String(bill.occurredLocalDate.prefix(7))
            result[monthKey, default: 0] += bill.amount.cents
        }

        switch timeRange {
        case .week:
            let start = startOfWeek(for: normalizedAnchorDate)
            let dates = (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
                return date
            }
            totals = dates.map { date in
                let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
                return dayTotals[dayKey, default: 0]
            }
            axisLabels = ["一", "二", "三", "四", "五", "六", "日"]
            pointLabels = dates.map(shortDateText)
        case .month:
            let start = startOfMonth(for: normalizedAnchorDate)
            let dayRange = calendar.range(of: .day, in: .month, for: start) ?? 1..<2
            let dates = dayRange.map { day in
                let date = calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
                return date
            }
            totals = dates.map { date in
                let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
                return dayTotals[dayKey, default: 0]
            }
            let month = calendar.component(.month, from: normalizedAnchorDate)
            let lastDay = dayRange.count
            axisLabels = ["\(month)/1", "\(month)/15", "\(month)/\(lastDay)"]
            pointLabels = dates.map(shortDateText)
        case .quarter:
            let start = quarterStart(for: normalizedAnchorDate)
            let end = calendar.date(byAdding: .month, value: 3, to: start) ?? start
            let weekStarts = (0..<13).map { offset in
                calendar.date(byAdding: .weekOfYear, value: offset, to: start) ?? start
            }
            totals = weekStarts.enumerated().map { index, weekStart in
                let nextWeekStart = weekStarts.indices.contains(index + 1) ? weekStarts[index + 1] : end
                let bucketEnd = min(nextWeekStart, end)
                let endDate = calendar.date(byAdding: .day, value: -1, to: bucketEnd) ?? weekStart
                let startKey = DayKeyFormatter.dayKey(for: weekStart, timeZone: calendar.timeZone)
                let endKey = DayKeyFormatter.dayKey(for: endDate, timeZone: calendar.timeZone)
                return dayTotals
                    .filter { $0.key >= startKey && $0.key <= endKey }
                    .reduce(0) { $0 + $1.value }
            }
            axisLabels = [
                shortDateText(weekStarts.first ?? start),
                shortDateText(weekStarts[min(6, weekStarts.count - 1)]),
                shortDateText(weekStarts.last ?? start)
            ]
            pointLabels = weekStarts.map(shortDateText)
        case .year:
            let year = calendar.component(.year, from: normalizedAnchorDate)
            totals = (1...12).map { month in
                let prefix = String(format: "%04d-%02d", year, month)
                return monthTotals[prefix, default: 0]
            }
            axisLabels = ["1月", "6月", "12月"]
            pointLabels = (1...12).map { "\($0)月" }
        case .custom:
            let start = calendar.date(byAdding: .day, value: -29, to: normalizedAnchorDate) ?? normalizedAnchorDate
            let dates = (0..<30).map { offset in
                calendar.date(byAdding: .day, value: offset, to: start) ?? start
            }
            totals = dates.map { date in
                let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
                return dayTotals[dayKey, default: 0]
            }
            axisLabels = [
                shortDateText(dates.first ?? start),
                shortDateText(dates[min(14, dates.count - 1)]),
                shortDateText(dates.last ?? start)
            ]
            pointLabels = dates.map(shortDateText)
        }

        let maxValue = totals.max() ?? 0
        let normalized = maxValue > 0 ? totals.map { Double($0) / Double(maxValue) } : totals.map { _ in 0 }
        let highlightIndex = totals.firstIndex(of: maxValue)
        return (normalized, highlightIndex, axisLabels, totals, pointLabels)
    }

    private func buildRanking(for bills: [BillRecord]) -> [RankingItem] {
        let totalCents = bills.reduce(0) { $0 + $1.amount.cents }
        guard totalCents > 0 else { return [] }

        let totals = bills.reduce(into: [UUID: (amount: Int, count: Int)]()) { result, bill in
            let categoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
            let current = result[categoryId] ?? (0, 0)
            result[categoryId] = (current.amount + bill.amount.cents, current.count + 1)
        }

        let sorted = totals.filter { $0.value.amount > 0 }.sorted { lhs, rhs in
            if rankSort == .most {
                return lhs.value.amount > rhs.value.amount
            }
            return lhs.value.amount < rhs.value.amount
        }

        return sorted.prefix(6).map { (id, value) in
            let category = categoriesById[id]
            let name = category?.name ?? "未分类"
            let iconName = category?.iconKey ?? "questionmark"
            let iconHex = category?.colorHex.map { UInt32($0) }
            let percent = Double(value.amount) / Double(totalCents)
            return RankingItem(
                id: id,
                title: name,
                iconName: iconName,
                iconColorHex: iconHex,
                count: value.count,
                percent: percent,
                amountCents: value.amount
            )
        }
    }

    private func categoryCount(for bills: [BillRecord]) -> Int {
        Set(bills.map { bill in
            bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
        }).count
    }

    private func makeRowItem(for bill: BillRecord) -> RowItem {
        let categoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
        let category = categoriesById[categoryId]
        let title = category?.name ?? "未分类"
        let iconName = category?.iconKey ?? "questionmark"
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

    private func startOfWeek(for date: Date) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    private func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private func quarterStart(for date: Date) -> Date {
        let month = calendar.component(.month, from: date)
        let quarterStartMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = quarterStartMonth
        components.day = 1
        return calendar.date(from: components) ?? date
    }

    private func shortDateText(for date: Date) -> String {
        "\(calendar.component(.month, from: date))/\(calendar.component(.day, from: date))"
    }

    private func makeTrendPeak(values: [Int], labels: [String]) -> TrendPeak? {
        guard let maxValue = values.max(), maxValue > 0, let index = values.firstIndex(of: maxValue) else {
            return nil
        }
        let label = labels.indices.contains(index) ? labels[index] : ""
        return TrendPeak(index: index, label: label, amountCents: maxValue)
    }

    private static func detailDateString(for bill: BillRecord) -> String {
        guard let date = DayKeyFormatter.date(from: bill.occurredLocalDate, timeZone: .autoupdatingCurrent) else {
            return bill.occurredLocalDate
        }
        return detailDateFormatter.string(from: date)
    }
}
