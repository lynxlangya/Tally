import Foundation
import SwiftUI
import Combine

@MainActor
final class RecurringBillFormViewModel: ObservableObject {
    @Published var selectedCategory: CategoryRecord?
    @Published var selectedType: BillType
    @Published private(set) var categories: [CategoryRecord] = []
    @Published var firstDate: Date
    @Published var amountText: String = ""
    @Published var note: String = ""
    @Published var repeatRule: RepeatRule = .daily
    @Published var errorMessage: String?

    let recurringRepository: RecurringRepository
    let categoryRepository: CategoryRepository

    let noteLimit = 50
    private let nowProvider: () -> Date
    private let existingTask: RecurringTaskRecord?

    init(
        recurringRepository: RecurringRepository,
        categoryRepository: CategoryRepository,
        existingTask: RecurringTaskRecord? = nil,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.recurringRepository = recurringRepository
        self.categoryRepository = categoryRepository
        self.existingTask = existingTask
        self.nowProvider = nowProvider

        if let existingTask {
            self.selectedType = existingTask.type
            self.firstDate = Self.normalizedFirstDate(existingTask.firstDate)
            self.amountText = Self.amountText(fromCents: existingTask.amount.cents)
            self.note = existingTask.note ?? ""
            self.repeatRule = RepeatRule(rawValue: existingTask.repeatRule) ?? .daily
        } else {
            self.selectedType = .expense
            self.firstDate = Self.defaultFirstDate(from: nowProvider())
        }
    }

    var isEditing: Bool {
        existingTask != nil
    }

    var isValid: Bool {
        selectedCategory != nil && amountValue > 0
    }

    var firstDateText: String {
        Self.firstDateFormatter.string(from: normalizedFirstDate(firstDate))
    }

    var nextFireText: String {
        let date = RecurringScheduler.computeNextFireDate(
            firstDate: normalizedFirstDate(firstDate),
            rule: repeatRule,
            now: nowProvider()
        )
        return Self.nextFireFormatter.string(from: date) + " " + Self.weekdayText(for: date)
    }

    var amountCents: Int {
        amountValue
    }

    var selectedCategoryColor: Color {
        guard let category = selectedCategory else { return Color.tallyInkFaint }
        let hex = category.colorHex.map { UInt32($0) } ?? CategoryColorPalette.defaultHex(for: category.id)
        return Color(hex: hex)
    }

    func loadCategories() {
        do {
            categories = try categoryRepository.list(type: selectedType)
            if let selectedCategory, selectedCategory.type != selectedType {
                self.selectedCategory = nil
            }
            if selectedCategory == nil,
               let existingTask,
               existingTask.type == selectedType,
               let categoryId = existingTask.categoryId,
               let category = categories.first(where: { $0.id == categoryId }) {
                selectedCategory = category
            }
            errorMessage = nil
        } catch {
            categories = []
            errorMessage = FeatureErrorMessage.message(for: error, fallback: "分类加载失败，请稍后重试")
        }
    }

    func selectType(_ type: BillType) {
        selectedType = type
        loadCategories()
    }

    func selectCategory(_ category: CategoryRecord) {
        selectedType = category.type
        selectedCategory = category
    }

    func selectRepeatRule(_ rule: RepeatRule) {
        repeatRule = rule
        guard !isEditing else { return }
        firstDate = Self.nextFirstDate(
            for: rule,
            preservingTimeFrom: firstDate,
            now: nowProvider()
        )
    }

    func save() -> Bool {
        guard let category = selectedCategory else {
            errorMessage = "请选择分类"
            return false
        }
        let cents = amountValue
        guard cents > 0 else {
            errorMessage = "金额需大于 0"
            return false
        }

        let now = nowProvider()
        let firstExecutionDate = normalizedFirstDate(firstDate)
        if !isEditing && firstExecutionDate <= now {
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
            id: existingTask?.id ?? UUID(),
            type: category.type,
            amount: Money(cents: cents),
            categoryId: category.id,
            note: trimmedNote,
            firstDate: firstExecutionDate,
            repeatRule: repeatRule.rawValue,
            nextFireDate: nextFireDate,
            hour: components.hour ?? 0,
            minute: components.minute ?? 0,
            lastRunAtUTC: existingTask?.lastRunAtUTC,
            isEnabled: existingTask?.isEnabled ?? true,
            createdAt: existingTask?.createdAt ?? now,
            updatedAt: now
        )

        do {
            if isEditing {
                try recurringRepository.update(record)
            } else {
                try recurringRepository.create(record)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = FeatureErrorMessage.message(for: error, fallback: "保存定时账单失败，请稍后重试")
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

    private static func nextFirstDate(
        for rule: RepeatRule,
        preservingTimeFrom timeSource: Date,
        now: Date
    ) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeSource)

        switch rule {
        case .daily:
            return defaultFirstDate(from: now)

        case .weeklyMonday:
            return nextDate(
                after: now,
                matching: timeComponents,
                weekday: 2,
                calendar: calendar
            )

        case .weeklySunday:
            return nextDate(
                after: now,
                matching: timeComponents,
                weekday: 1,
                calendar: calendar
            )

        case .monthlyFirst:
            return nextMonthlyDate(
                day: 1,
                after: now,
                matching: timeComponents,
                calendar: calendar
            )

        case .monthlyLast:
            return nextMonthlyLastDate(
                after: now,
                matching: timeComponents,
                calendar: calendar
            )
        }
    }

    private static func nextDate(
        after now: Date,
        matching timeComponents: DateComponents,
        weekday: Int,
        calendar: Calendar
    ) -> Date {
        var components = timeComponents
        components.weekday = weekday
        components.second = 0
        return calendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? defaultFirstDate(from: now)
    }

    private static func nextMonthlyDate(
        day: Int,
        after now: Date,
        matching timeComponents: DateComponents,
        calendar: Calendar
    ) -> Date {
        func candidate(in date: Date) -> Date? {
            var components = calendar.dateComponents([.year, .month], from: date)
            components.day = day
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            components.second = 0
            return calendar.date(from: components)
        }

        if let currentMonth = candidate(in: now), currentMonth > now {
            return currentMonth
        }
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
           let nextCandidate = candidate(in: nextMonth) {
            return nextCandidate
        }
        return defaultFirstDate(from: now)
    }

    private static func nextMonthlyLastDate(
        after now: Date,
        matching timeComponents: DateComponents,
        calendar: Calendar
    ) -> Date {
        func candidate(in date: Date) -> Date? {
            guard let range = calendar.range(of: .day, in: .month, for: date) else { return nil }
            var components = calendar.dateComponents([.year, .month], from: date)
            components.day = range.upperBound - 1
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            components.second = 0
            return calendar.date(from: components)
        }

        if let currentMonth = candidate(in: now), currentMonth > now {
            return currentMonth
        }
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
           let nextCandidate = candidate(in: nextMonth) {
            return nextCandidate
        }
        return defaultFirstDate(from: now)
    }

    private static func amountText(fromCents cents: Int) -> String {
        let yuan = cents / 100
        let cent = cents % 100
        if cent == 0 {
            return "\(yuan)"
        }
        let centText = cent < 10 ? "0\(cent)" : "\(cent)"
        return "\(yuan).\(centText)"
    }

    private static let firstDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private static let nextFireFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static func weekdayText(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
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
}
