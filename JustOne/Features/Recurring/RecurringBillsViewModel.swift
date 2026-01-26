import Foundation
import SwiftUI
import Combine

@MainActor
final class RecurringBillsViewModel: ObservableObject {
    struct Item: Identifiable {
        let id: UUID
        let icon: String
        let iconColor: Color
        let title: String
        let amountCents: Int
        let repeatText: String
        let nextFireText: String
        let isIncome: Bool
    }

    @Published private(set) var items: [Item] = []

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
            items = tasks
                .sorted { $0.nextFireDate < $1.nextFireDate }
                .map { task in
                    let display = categoryDisplay(for: task, categoryMap: categoryMap)
                    let repeatText = RepeatRule(rawValue: task.repeatRule)?.title ?? "每天"
                    let nextText = "下次 \(Self.formatDate(task.nextFireDate))"
                    return Item(
                        id: task.id,
                        icon: display.icon,
                        iconColor: display.color,
                        title: display.name,
                        amountCents: task.amount.cents,
                        repeatText: repeatText,
                        nextFireText: nextText,
                        isIncome: task.type == .income
                    )
                }
        } catch {
            items = []
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

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
