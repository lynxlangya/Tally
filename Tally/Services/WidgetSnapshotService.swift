import Foundation
import os
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshotService {
    private static let logger = Logger(subsystem: "com.langya.Tally", category: "widget")

    static func refresh(using repository: BillRepository, now: Date = Date()) {
        do {
            let todayKey = DayKeyFormatter.dayKey(for: now)
            let recentStartKey = dayKey(byAdding: -6, to: now) ?? todayKey
            let monthKey = String(todayKey.prefix(7))
            let monthBills = try repository.list(monthKey: monthKey, type: nil)
            let recentBills = try repository.list(fromDayKey: recentStartKey, toDayKey: todayKey, type: nil)
            let snapshot = buildSnapshot(fromMonthBills: monthBills, recentBills: recentBills, now: now)
            WidgetDataStore.saveSnapshot(snapshot)
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.quickEntry)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.summaryTrend)
            #endif
        } catch {
            logger.error("Widget snapshot refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func buildSnapshot(
        fromMonthBills monthBills: [BillRecord],
        recentBills: [BillRecord],
        now: Date
    ) -> WidgetSnapshot {
        let calendar = Calendar.current
        let todayKey = DayKeyFormatter.dayKey(for: now)
        let yesterdayKey = dayKey(byAdding: -1, to: now)
        var todayExpense = 0
        var todayEntryCount = 0
        var yesterdayExpense = 0
        var hasYesterdayExpense = false
        var monthExpense = 0
        var monthIncome = 0
        var monthExpenseByDay: [String: Int] = [:]
        var recentExpenseByDay: [String: Int] = [:]

        for bill in monthBills {
            if bill.type == .expense {
                monthExpense += bill.amount.cents
                monthExpenseByDay[bill.occurredLocalDate, default: 0] += bill.amount.cents
            } else {
                monthIncome += bill.amount.cents
            }
        }

        for bill in recentBills where bill.type == .expense {
            recentExpenseByDay[bill.occurredLocalDate, default: 0] += bill.amount.cents
            if bill.occurredLocalDate == todayKey {
                todayExpense += bill.amount.cents
                todayEntryCount += 1
            }
            if bill.occurredLocalDate == yesterdayKey {
                yesterdayExpense += bill.amount.cents
                hasYesterdayExpense = true
            }
        }

        let monthBalance = monthIncome - monthExpense
        let trend7Raw = buildRecentExpenseValues(from: recentExpenseByDay, now: now, days: 7)
        let average7 = trend7Raw.isEmpty ? 0 : trend7Raw.reduce(0, +) / trend7Raw.count

        let sparkline = buildMonthSparkline(from: monthExpenseByDay, now: now)
        let trend7 = normalize(values: trend7Raw)

        return WidgetSnapshot(
            updatedAt: now,
            quickEntry: QuickEntryWidgetModel(
                todayExpenseCents: todayExpense,
                todayEntryCount: todayEntryCount,
                yesterdayExpenseCents: hasYesterdayExpense ? yesterdayExpense : nil,
                currencySymbol: "¥"
            ),
            summary: SummaryTrendWidgetModel(
                monthExpenseCents: monthExpense,
                monthIncomeCents: monthIncome,
                monthBalanceCents: monthBalance,
                sparkline: sparkline,
                trend7: trend7,
                monthNumber: calendar.component(.month, from: now),
                average7Cents: average7
            )
        )
    }

    private static func buildMonthSparkline(from expenseByDay: [String: Int], now: Date) -> [Double] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: now) else {
            return [0.2, 0.3, 0.15, 0.4, 0.25, 0.35, 0.2]
        }
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let values = range.compactMap { day -> Int? in
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            guard let date = calendar.date(from: comps) else { return nil }
            let key = DayKeyFormatter.dayKey(for: date)
            return expenseByDay[key, default: 0]
        }
        return normalize(values: values)
    }

    private static func buildRecentExpenseValues(from expenseByDay: [String: Int], now: Date, days: Int) -> [Int] {
        stride(from: days - 1, through: 0, by: -1).map { offset in
            guard let key = dayKey(byAdding: -offset, to: now) else { return 0 }
            return expenseByDay[key, default: 0]
        }
    }

    private static func normalize(values: [Int]) -> [Double] {
        let maxValue = values.max() ?? 1
        if maxValue <= 0 {
            return values.map { _ in 0 }
        }
        return values.map { Double($0) / Double(maxValue) }
    }

    private static func dayKey(byAdding days: Int, to date: Date) -> String? {
        Calendar.current.date(byAdding: .day, value: days, to: date).map { DayKeyFormatter.dayKey(for: $0) }
    }
}
