import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetSnapshotService {
    static func refresh(using repository: BillRepository, now: Date = Date()) {
        do {
            let todayKey = DayKeyFormatter.dayKey(for: now)
            let monthKey = String(todayKey.prefix(7))
            let monthBills = try repository.list(monthKey: monthKey, type: nil)
            let snapshot = buildSnapshot(from: monthBills, now: now)
            WidgetDataStore.saveSnapshot(snapshot)
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.quickEntry)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.summaryTrend)
            #endif
        } catch {
            // 保持静默失败，避免影响主流程
        }
    }

    private static func buildSnapshot(from bills: [BillRecord], now: Date) -> WidgetSnapshot {
        let todayKey = DayKeyFormatter.dayKey(for: now)
        var todayExpense = 0
        var monthExpense = 0
        var monthIncome = 0
        var expenseByDay: [String: Int] = [:]

        for bill in bills {
            if bill.type == .expense {
                monthExpense += bill.amount.cents
                expenseByDay[bill.occurredLocalDate, default: 0] += bill.amount.cents
                if bill.occurredLocalDate == todayKey {
                    todayExpense += bill.amount.cents
                }
            } else {
                monthIncome += bill.amount.cents
            }
        }
        let monthBalance = monthIncome - monthExpense

        let sparkline = buildSparkline(from: expenseByDay, now: now)

        return WidgetSnapshot(
            updatedAt: now,
            quickEntry: QuickEntryWidgetModel(todayExpenseCents: todayExpense, currencySymbol: "¥"),
            summary: SummaryTrendWidgetModel(
                monthExpenseCents: monthExpense,
                monthIncomeCents: monthIncome,
                monthBalanceCents: monthBalance,
                sparkline: sparkline
            )
        )
    }

    private static func buildSparkline(from expenseByDay: [String: Int], now: Date) -> [Double] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: now) else {
            return [0.2, 0.3, 0.15, 0.4, 0.25, 0.35, 0.2]
        }
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let days = range.compactMap { day -> Date? in
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            return calendar.date(from: comps)
        }
        let values = days.map { date -> Double in
            let key = DayKeyFormatter.dayKey(for: date)
            return Double(expenseByDay[key, default: 0])
        }
        let maxValue = values.max() ?? 1
        if maxValue <= 0 {
            return values.map { _ in 0 }
        }
        return values.map { $0 / maxValue }
    }
}
