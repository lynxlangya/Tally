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
            errorMessage = TallyLocalization.text("recurring_load_failed", locale: LanguageManager.shared.currentLocale)
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
            errorMessage = TallyLocalization.text(isEnabled ? "recurring_enable_failed" : "recurring_pause_failed", locale: LanguageManager.shared.currentLocale)
        }
    }

    func delete(id: UUID) {
        do {
            try recurringRepository.delete(id: id)
            load()
        } catch {
            errorMessage = TallyLocalization.text("recurring_delete_failed", locale: LanguageManager.shared.currentLocale)
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
        return (TallyLocalization.text(.uncategorized, locale: LanguageManager.shared.currentLocale), "tag", Color(hex: hex))
    }

    private static func dateText(_ date: Date) -> String {
        TallyLocalization.monthDayTitle(for: date, locale: LanguageManager.shared.currentLocale)
    }

    private static func weekdayText(for date: Date) -> String {
        TallyLocalization.weekdayTitle(for: date, locale: LanguageManager.shared.currentLocale)
    }

    private static func formatNextFireDate(_ date: Date) -> String {
        "\(dateText(date)) \(weekdayText(for: date))"
    }

    private static func ruleText(for rawValue: String) -> String {
        let locale = LanguageManager.shared.currentLocale
        guard let rule = RepeatRule(rawValue: rawValue) else { return TallyLocalization.text("repeat_daily", locale: locale) }
        switch rule {
        case .daily:
            return TallyLocalization.text("repeat_daily", locale: locale)
        case .weeklyMonday, .weeklySunday:
            return TallyLocalization.text("repeat_weekly", locale: locale)
        case .monthlyFirst:
            return TallyLocalization.text("repeat_monthly_first", locale: locale)
        case .monthlyLast:
            return TallyLocalization.text("repeat_monthly_last", locale: locale)
        }
    }

    private static func isMonthlyRule(_ rawValue: String) -> Bool {
        rawValue == RepeatRule.monthlyFirst.rawValue || rawValue == RepeatRule.monthlyLast.rawValue
    }
}
