import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    struct Summary {
        let monthTitle: String
        let expenseCents: Int
        let incomeCents: Int

        var balance: Int {
            incomeCents - expenseCents
        }

        var balanceCents: Int {
            abs(balance)
        }

        var balanceSign: String {
            balance >= 0 ? "+" : "-"
        }
    }

    struct Item: Identifiable {
        let id: UUID
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
        let amountCents: Int
        let isIncome: Bool
    }

    struct Group: Identifiable {
        let id: String
        let title: String
        let totalCents: Int
        let totalSign: String
        let items: [Item]
    }

    @Published private(set) var summary: Summary
    @Published private(set) var groups: [Group] = []

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private let nowProvider: () -> Date
    private var billById: [UUID: BillRecord] = [:]
    private var loadedBills: [BillRecord] = []

    init(
        repository: BillRepository,
        categoryRepository: CategoryRepository,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.billRepository = repository
        self.categoryRepository = categoryRepository
        self.nowProvider = nowProvider
        self.summary = Summary(monthTitle: "", expenseCents: 0, incomeCents: 0)
    }

    func load() {
        do {
            let monthKey = currentMonthKey()
            let bills = try billRepository.list(monthKey: monthKey, type: nil)
            loadedBills = bills
            billById = Dictionary(uniqueKeysWithValues: bills.map { ($0.id, $0) })

            let categoryMap = loadCategories()
            updateSummary(with: bills)
            groups = buildGroups(from: bills, categoryMap: categoryMap)
            WidgetSnapshotService.refresh(using: billRepository, now: nowProvider())
        } catch {
            loadedBills = []
            billById = [:]
            summary = Summary(monthTitle: monthTitle(for: nowProvider()), expenseCents: 0, incomeCents: 0)
            groups = []
        }
    }

    var dailyAverageCents: Int {
        let elapsedDays = max(1, daysElapsedInMonth(for: nowProvider()))
        return summary.expenseCents / elapsedDays
    }

    var trend7Cents: [Int] {
        let calendar = Calendar.current
        let now = nowProvider()
        let today = calendar.startOfDay(for: now)
        let dayKeys = (0..<7).compactMap { offset -> String? in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else {
                return nil
            }
            return DayKeyFormatter.dayKey(for: date)
        }
        let daySet = Set(dayKeys)
        let expenseTotals = loadedBills
            .filter { $0.type == .expense && daySet.contains($0.occurredLocalDate) }
            .reduce(into: [String: Int]()) { result, bill in
                result[bill.occurredLocalDate, default: 0] += bill.amount.cents
            }
        return dayKeys.map { expenseTotals[$0, default: 0] }
    }

    var trend7Labels: [String] {
        let calendar = Calendar.current
        let now = nowProvider()
        let today = calendar.startOfDay(for: now)
        return (0..<7).compactMap { offset -> String? in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else {
                return nil
            }
            let weekday = max(1, calendar.component(.weekday, from: date)) - 1
            return chineseWeekdayText(at: weekday)
        }
    }

    var currentWeekdayText: String {
        let calendar = Calendar.current
        let weekday = max(1, calendar.component(.weekday, from: nowProvider())) - 1
        return chineseWeekdayText(at: weekday)
    }

    func bill(for id: UUID) -> BillRecord? {
        billById[id]
    }

    func deleteBill(id: UUID) {
        let now = nowProvider()
        do {
            try billRepository.delete(id: id)
            WidgetSnapshotService.refresh(using: billRepository, now: now)
            NotificationCenter.default.post(name: .billDidChange, object: nil)
            load()
        } catch {
            // TODO: surface error when error handling UX is defined.
        }
    }

    private func loadCategories() -> [UUID: CategoryRecord] {
        var result: [UUID: CategoryRecord] = [:]
        if let expense = try? categoryRepository.list(type: .expense) {
            for item in expense {
                result[item.id] = item
            }
        }
        if let income = try? categoryRepository.list(type: .income) {
            for item in income {
                result[item.id] = item
            }
        }
        return result
    }

    private func updateSummary(with bills: [BillRecord]) {
        let now = nowProvider()
        let expenseCents = bills
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount.cents }
        let incomeCents = bills
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount.cents }

        summary = Summary(
            monthTitle: monthTitle(for: now),
            expenseCents: expenseCents,
            incomeCents: incomeCents
        )
    }

    private func buildGroups(
        from bills: [BillRecord],
        categoryMap: [UUID: CategoryRecord]
    ) -> [Group] {
        let now = nowProvider()
        let todayKey = DayKeyFormatter.dayKey(for: now)
        let yesterdayKey = DayKeyFormatter.dayKey(for: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now)

        let grouped = Dictionary(grouping: bills) { $0.occurredLocalDate }
        let groupsWithDate = grouped.compactMap { key, items -> (Group, String)? in
            let sortedItems = items.sorted {
                if $0.occurredAtUTC != $1.occurredAtUTC {
                    return $0.occurredAtUTC > $1.occurredAtUTC
                }
                return $0.createdAt > $1.createdAt
            }
            let viewItems = sortedItems.map { bill in
                let category = categoryDisplay(for: bill, categoryMap: categoryMap)
                let timeText = BillTimeFormatter.timeText(for: bill)
                let noteText = bill.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let title = noteText.isEmpty ? category.name : noteText
                let subtitle = "\(category.name) · \(timeText)"

                return Item(
                    id: bill.id,
                    icon: category.icon,
                    iconColor: category.color,
                    title: title,
                    subtitle: subtitle,
                    amountCents: bill.amount.cents,
                    isIncome: bill.type == .income
                )
            }

            let total = items.reduce(0) { partial, bill in
                let sign = bill.type == .income ? 1 : -1
                return partial + sign * bill.amount.cents
            }

            let group = Group(
                id: key,
                title: dayTitle(for: key, todayKey: todayKey, yesterdayKey: yesterdayKey),
                totalCents: abs(total),
                totalSign: total >= 0 ? "+" : "-",
                items: viewItems
            )
            return (group, key)
        }

        return groupsWithDate
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    private func categoryDisplay(
        for bill: BillRecord,
        categoryMap: [UUID: CategoryRecord]
    ) -> (name: String, icon: String, color: Color) {
        let fallbackId = SystemCategoryID.uncategorized(for: bill.type)
        let categoryId = bill.categoryId ?? fallbackId
        if let category = categoryMap[categoryId] {
            let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
            return (category.name, category.iconKey, Color(hex: hex))
        }
        let hex = CategoryColorPalette.defaultHex(for: fallbackId)
        return ("未分类", "questionmark", Color(hex: hex))
    }

    private func dayTitle(for dayKey: String, todayKey: String, yesterdayKey: String) -> String {
        if dayKey == todayKey { return "今天" }
        if dayKey == yesterdayKey { return "昨天" }
        let parts = dayKey.split(separator: "-")
        if parts.count == 3, let month = Int(parts[1]), let day = Int(parts[2]) {
            return "\(month)月\(day)日"
        }
        return dayKey
    }

    private func monthTitle(for date: Date) -> String {
        let components = Calendar.current.dateComponents(in: .current, from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return "\(year)年\(month)月"
    }

    private func currentMonthKey() -> String {
        let now = nowProvider()
        let dayKey = DayKeyFormatter.dayKey(for: now)
        return String(dayKey.prefix(7))
    }

    private func daysElapsedInMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? day
        return min(max(day, 1), max(daysInMonth, 1))
    }

    private func chineseWeekdayText(at zeroBasedWeekday: Int) -> String {
        let symbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        guard symbols.indices.contains(zeroBasedWeekday) else { return "" }
        return symbols[zeroBasedWeekday]
    }
}
