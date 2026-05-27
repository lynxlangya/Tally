import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    struct StreakDay: Identifiable, Equatable {
        let id: String
        let label: String
        let count: Int
        let isRecorded: Bool
        let isFuture: Bool

        var normalizedHeight: Double {
            guard count > 0 else { return 0 }
            return min(1, Double(count) / 7.0)
        }
    }

    @Published private(set) var billCount: Int = 0
    @Published private(set) var recordedDayCount: Int = 0
    @Published private(set) var streakDays: [StreakDay] = []
    @Published private(set) var expenseCategoryCount: Int = 0
    @Published private(set) var incomeCategoryCount: Int = 0
    @Published private(set) var enabledRecurringCount: Int = 0
    @Published private(set) var nextRecurringChip: String?
    @Published private(set) var errorMessage: String?

    private let billRepository: BillRepository
    private let categoryRepository: CategoryRepository
    private let recurringRepository: RecurringRepository
    private let calendar: Calendar
    private let nowProvider: () -> Date

    init(
        billRepository: BillRepository,
        categoryRepository: CategoryRepository,
        recurringRepository: RecurringRepository,
        calendar: Calendar = Calendar(identifier: .gregorian),
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.billRepository = billRepository
        self.categoryRepository = categoryRepository
        self.recurringRepository = recurringRepository
        var calendar = calendar
        calendar.timeZone = .current
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    func load() {
        do {
            let bills = try billRepository.list().filter { $0.deletedAt == nil }
            billCount = bills.count
            recordedDayCount = Set(bills.map(\.occurredLocalDate)).count

            let weekRange = currentWeekRange()
            let weekBills = try billRepository.list(
                fromDayKey: weekRange.dayKeys.first ?? "",
                toDayKey: weekRange.dayKeys.last ?? "",
                type: nil
            )
            let countsByDay = Dictionary(grouping: weekBills.filter { $0.deletedAt == nil }, by: \.occurredLocalDate)
                .mapValues(\.count)
            streakDays = zip(weekRange.dates, weekRange.dayKeys).enumerated().map { index, pair in
                let date = pair.0
                let dayKey = pair.1
                let count = countsByDay[dayKey] ?? 0
                return StreakDay(
                    id: dayKey,
                    label: Self.weekdayLabels[index],
                    count: count,
                    isRecorded: count > 0,
                    isFuture: date > weekRange.todayStart
                )
            }

            expenseCategoryCount = try categoryRepository.count(type: .expense)
            incomeCategoryCount = try categoryRepository.count(type: .income)

            let enabledRecurring = try recurringRepository.list()
                .filter(\.isEnabled)
                .sorted { $0.nextFireDate < $1.nextFireDate }
            enabledRecurringCount = enabledRecurring.count
            nextRecurringChip = enabledRecurring.first.map { Self.nextFireFormatter.string(from: $0.nextFireDate) }
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    var recordedDayKeysThisWeek: Set<String> {
        Set(streakDays.filter(\.isRecorded).map(\.id))
    }

    var weeklyRecordedCount: Int {
        recordedDayKeysThisWeek.count
    }

    var categorySubtitle: String {
        "支出 \(expenseCategoryCount) · 收入 \(incomeCategoryCount)"
    }

    var recurringSubtitle: String {
        "\(enabledRecurringCount) 条已启用"
    }

    private func currentWeekRange() -> (dates: [Date], dayKeys: [String], todayStart: Date) {
        let now = nowProvider()
        let todayStart = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: todayStart)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: todayStart) ?? todayStart
        let dates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
        let dayKeys = dates.map { DayKeyFormatter.dayKey(for: $0, timeZone: calendar.timeZone) }
        return (dates, dayKeys, todayStart)
    }

    private static let weekdayLabels = ["一", "二", "三", "四", "五", "六", "日"]

    private static let nextFireFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}
