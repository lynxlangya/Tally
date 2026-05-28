import Foundation
import SwiftUI
import Combine

@MainActor
final class RecurringBillsViewModel: ObservableObject {
    struct Item: Identifiable {
        let id: UUID
        let task: RecurringTaskRecord
        let icon: String
        let iconColor: Color
        let title: String
        let amountCents: Int
        let ruleText: String
        let nextFireText: String
        let isIncome: Bool
        let isEnabled: Bool
    }

    @Published private(set) var items: [Item] = []
    @Published private(set) var enabledCount: Int = 0
    @Published private(set) var pausedCount: Int = 0
    @Published private(set) var monthlyFixedExpenseCents: Int = 0
    @Published private(set) var errorMessage: String?

    private let recurringRepository: RecurringRepository
    private let categoryRepository: CategoryRepository

    init(recurringRepository: RecurringRepository, categoryRepository: CategoryRepository) {
        self.recurringRepository = recurringRepository
        self.categoryRepository = categoryRepository
    }

    func load() {
        do {
            let tasks = try recurringRepository.list()
            let categoryMap = loadCategories()
            enabledCount = tasks.filter { $0.isEnabled }.count
            pausedCount = tasks.count - enabledCount
            monthlyFixedExpenseCents = tasks
                .filter { $0.isEnabled && $0.type == .expense && Self.isMonthlyRule($0.repeatRule) }
                .reduce(0) { $0 + $1.amount.cents }
            items = tasks
                .sorted { $0.nextFireDate < $1.nextFireDate }
                .map { task in
                    let display = categoryDisplay(for: task, categoryMap: categoryMap)
                    return Item(
                        id: task.id,
                        task: task,
                        icon: display.icon,
                        iconColor: display.color,
                        title: display.name,
                        amountCents: task.amount.cents,
                        ruleText: Self.ruleText(for: task.repeatRule),
                        nextFireText: Self.formatNextFireDate(task.nextFireDate),
                        isIncome: task.type == .income,
                        isEnabled: task.isEnabled
                    )
                }
            errorMessage = nil
        } catch {
            errorMessage = "定时账单加载失败，请稍后重试"
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    func toggleEnabled(id: UUID, isEnabled: Bool) {
        do {
            try recurringRepository.setEnabled(id: id, isEnabled: isEnabled)
            load()
        } catch {
            errorMessage = isEnabled ? "启用定时账单失败，请稍后重试" : "暂停定时账单失败，请稍后重试"
        }
    }

    func delete(id: UUID) {
        do {
            try recurringRepository.delete(id: id)
            load()
        } catch {
            errorMessage = "删除定时账单失败，请稍后重试"
        }
    }

    private func loadCategories() -> [UUID: CategoryRecord] {
        var map: [UUID: CategoryRecord] = [:]
        if let expense = try? categoryRepository.list(type: .expense) {
            expense.forEach { map[$0.id] = $0 }
        }
        if let income = try? categoryRepository.list(type: .income) {
            income.forEach { map[$0.id] = $0 }
        }
        return map
    }

    private func categoryDisplay(
        for task: RecurringTaskRecord,
        categoryMap: [UUID: CategoryRecord]
    ) -> (name: String, icon: String, color: Color) {
        let fallbackId = SystemCategoryID.uncategorized(for: task.type)
        let categoryId = task.categoryId ?? fallbackId
        if let category = categoryMap[categoryId] {
            let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
            return (category.name, category.iconKey, Color(hex: hex))
        }
        let hex = CategoryColorPalette.defaultHex(for: fallbackId)
        return ("未分类", "questionmark", Color(hex: hex))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static func formatNextFireDate(_ date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return "\(dateFormatter.string(from: date)) \(weekdayText(for: weekday))"
    }

    private static func weekdayText(for weekday: Int) -> String {
        switch weekday {
        case 1: return "周日"
        case 2: return "周一"
        case 3: return "周二"
        case 4: return "周三"
        case 5: return "周四"
        case 6: return "周五"
        case 7: return "周六"
        default: return "周一"
        }
    }

    private static func ruleText(for rawValue: String) -> String {
        guard let rule = RepeatRule(rawValue: rawValue) else { return "每日" }
        switch rule {
        case .daily:
            return "每日"
        case .weeklyMonday, .weeklySunday:
            return "每周"
        case .monthlyFirst:
            return "月初"
        case .monthlyLast:
            return "月末"
        }
    }

    private static func isMonthlyRule(_ rawValue: String) -> Bool {
        rawValue == RepeatRule.monthlyFirst.rawValue || rawValue == RepeatRule.monthlyLast.rawValue
    }
}
