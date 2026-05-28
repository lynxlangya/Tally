import Foundation

struct BillsListTrendModel {
    let points: [Double]
    let highlightIndex: Int?
    let axisLabels: [String]
    let valuesCents: [Int]
    let peak: BillsListViewModel.TrendPeak?
}

struct BillsListTrendBuilder {
    let timeRange: BillsListViewModel.TimeRange
    let anchorDate: Date
    let calendar: Calendar

    func build(for bills: [BillRecord]) -> BillsListTrendModel {
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
            let start = startOfWeek(for: anchorDate)
            let dates = (0..<7).map { offset in
                calendar.date(byAdding: .day, value: offset, to: start) ?? start
            }
            totals = dates.map { date in
                let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
                return dayTotals[dayKey, default: 0]
            }
            axisLabels = ["一", "二", "三", "四", "五", "六", "日"]
            pointLabels = dates.map(shortDateText)
        case .month:
            let start = startOfMonth(for: anchorDate)
            let dayRange = calendar.range(of: .day, in: .month, for: start) ?? 1..<2
            let dates = dayRange.map { day in
                calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
            }
            totals = dates.map { date in
                let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
                return dayTotals[dayKey, default: 0]
            }
            let month = calendar.component(.month, from: anchorDate)
            let lastDay = dayRange.count
            axisLabels = ["\(month)/1", "\(month)/15", "\(month)/\(lastDay)"]
            pointLabels = dates.map(shortDateText)
        case .quarter:
            let start = quarterStart(for: anchorDate)
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
                shortDateText(for: weekStarts.first ?? start),
                shortDateText(for: weekStarts[min(6, weekStarts.count - 1)]),
                shortDateText(for: weekStarts.last ?? start)
            ]
            pointLabels = weekStarts.map(shortDateText)
        case .year:
            let year = calendar.component(.year, from: anchorDate)
            totals = (1...12).map { month in
                let prefix = String(format: "%04d-%02d", year, month)
                return monthTotals[prefix, default: 0]
            }
            axisLabels = ["1月", "6月", "12月"]
            pointLabels = (1...12).map { "\($0)月" }
        case .custom:
            let start = calendar.date(byAdding: .day, value: -29, to: anchorDate) ?? anchorDate
            let dates = (0..<30).map { offset in
                calendar.date(byAdding: .day, value: offset, to: start) ?? start
            }
            totals = dates.map { date in
                let dayKey = DayKeyFormatter.dayKey(for: date, timeZone: calendar.timeZone)
                return dayTotals[dayKey, default: 0]
            }
            axisLabels = [
                shortDateText(for: dates.first ?? start),
                shortDateText(for: dates[min(14, dates.count - 1)]),
                shortDateText(for: dates.last ?? start)
            ]
            pointLabels = dates.map(shortDateText)
        }

        let maxValue = totals.max() ?? 0
        let points = maxValue > 0 ? totals.map { Double($0) / Double(maxValue) } : totals.map { _ in 0 }
        let highlightIndex = totals.firstIndex(of: maxValue)
        let peak = makePeak(values: totals, labels: pointLabels)

        return BillsListTrendModel(
            points: points,
            highlightIndex: highlightIndex,
            axisLabels: axisLabels,
            valuesCents: totals,
            peak: peak
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

    private func makePeak(values: [Int], labels: [String]) -> BillsListViewModel.TrendPeak? {
        guard let maxValue = values.max(), maxValue > 0, let index = values.firstIndex(of: maxValue) else {
            return nil
        }
        let label = labels.indices.contains(index) ? labels[index] : ""
        return BillsListViewModel.TrendPeak(index: index, label: label, amountCents: maxValue)
    }
}
