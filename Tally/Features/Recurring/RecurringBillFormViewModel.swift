import Foundation
import SwiftUI
import Combine

@MainActor
final class RecurringBillFormViewModel: ObservableObject {
    @Published var selectedCategory: CategoryRecord?
    @Published var firstDate: Date
    @Published var amountText: String = ""
    @Published var note: String = ""
    @Published var repeatRule: RepeatRule = .daily
    @Published var errorMessage: String?

    let recurringRepository: RecurringRepository
    let categoryRepository: CategoryRepository

    let noteLimit = 50
    private let nowProvider: () -> Date

    init(
        recurringRepository: RecurringRepository,
        categoryRepository: CategoryRepository,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.recurringRepository = recurringRepository
        self.categoryRepository = categoryRepository
        self.nowProvider = nowProvider
        self.firstDate = Self.defaultFirstDate(from: nowProvider())
    }

    var isValid: Bool {
        selectedCategory != nil && amountValue > 0
    }

    var firstDateText: String {
        Self.firstDateFormatter.string(from: normalizedFirstDate(firstDate))
    }

    var selectedCategoryColor: Color {
        guard let category = selectedCategory else { return JOColors.textSecondary }
        let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }

    func selectCategory(_ category: CategoryRecord) {
        selectedCategory = category
    }

    func save() -> Bool {
        guard let category = selectedCategory else {
            errorMessage = "请选择分类"
            return false
        }
        let cents = amountValue
        guard cents > 0 else {
            errorMessage = "请输入金额"
            return false
        }

        let now = nowProvider()
        let firstExecutionDate = normalizedFirstDate(firstDate)
        guard firstExecutionDate > now else {
            errorMessage = "首次执行时间必须晚于当前时间"
            return false
        }
        let nextFireDate = RecurringScheduler.computeNextFireDate(
            firstDate: firstExecutionDate,
            rule: repeatRule,
            now: now
        )
        let components = Calendar.current.dateComponents([.hour, .minute], from: firstExecutionDate)

        let record = RecurringTaskRecord(
            id: UUID(),
            type: category.type,
            amount: Money(cents: cents),
            categoryId: category.id,
            note: trimmedNote,
            firstDate: firstExecutionDate,
            repeatRule: repeatRule.rawValue,
            nextFireDate: nextFireDate,
            hour: components.hour ?? 0,
            minute: components.minute ?? 0,
            lastRunAtUTC: nil,
            isEnabled: true,
            createdAt: now,
            updatedAt: now
        )

        do {
            try recurringRepository.create(record)
            errorMessage = nil
            return true
        } catch {
            errorMessage = String(describing: error)
            return false
        }
    }

    var trimmedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return String(trimmed.prefix(noteLimit))
    }

    func sanitizedAmount(_ input: String) -> String {
        let filtered = input.filter { "0123456789.".contains($0) }
        let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return String(parts.prefix(2).joined(separator: ".")) }
        if parts.count == 2 {
            let integer = String(parts[0])
            let decimal = String(parts[1].prefix(2))
            return integer + "." + decimal
        }
        return filtered
    }

    private var amountValue: Int {
        let filtered = sanitizedAmount(amountText)
        guard let decimal = Decimal(string: filtered.isEmpty ? "0" : filtered) else { return 0 }
        let cents = NSDecimalNumber(decimal: decimal)
            .multiplying(byPowerOf10: 2)
            .intValue
        return max(0, cents)
    }

    func normalizedFirstDate(_ date: Date) -> Date {
        Self.normalizedFirstDate(date)
    }

    private static func normalizedFirstDate(_ date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return Calendar.current.date(from: components) ?? date
    }

    private static func defaultFirstDate(from now: Date) -> Date {
        let normalizedNow = normalizedFirstDate(now)
        let calendar = Calendar.current
        let hourStart = calendar.date(
            from: calendar.dateComponents([.year, .month, .day, .hour], from: normalizedNow)
        ) ?? normalizedNow
        return calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? normalizedNow
    }

    private static let firstDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}
