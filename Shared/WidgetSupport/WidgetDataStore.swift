import Foundation
import os

struct QuickEntryWidgetModel: Codable, Equatable {
    let todayExpenseCents: Int
    let todayEntryCount: Int
    let yesterdayExpenseCents: Int?
    let currencySymbol: String

    init(
        todayExpenseCents: Int,
        todayEntryCount: Int = 0,
        yesterdayExpenseCents: Int? = nil,
        currencySymbol: String = MoneyFormatter.currencySymbol()
    ) {
        self.todayExpenseCents = todayExpenseCents
        self.todayEntryCount = todayEntryCount
        self.yesterdayExpenseCents = yesterdayExpenseCents
        self.currencySymbol = currencySymbol
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        todayExpenseCents = try container.decodeIfPresent(Int.self, forKey: .todayExpenseCents) ?? 0
        todayEntryCount = try container.decodeIfPresent(Int.self, forKey: .todayEntryCount) ?? 0
        yesterdayExpenseCents = try container.decodeIfPresent(Int.self, forKey: .yesterdayExpenseCents)
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol) ?? MoneyFormatter.currencySymbol()
    }
}

struct SummaryTrendWidgetModel: Codable, Equatable {
    let monthExpenseCents: Int
    let monthIncomeCents: Int
    let monthBalanceCents: Int
    let sparkline: [Double]
    let trend7: [Double]
    let monthNumber: Int
    let year: Int
    let average7Cents: Int
    let currencySymbol: String

    init(
        monthExpenseCents: Int,
        monthIncomeCents: Int,
        monthBalanceCents: Int,
        sparkline: [Double],
        trend7: [Double]? = nil,
        monthNumber: Int = Calendar.current.component(.month, from: Date()),
        year: Int = Calendar.current.component(.year, from: Date()),
        average7Cents: Int = 0,
        currencySymbol: String = MoneyFormatter.currencySymbol()
    ) {
        self.monthExpenseCents = monthExpenseCents
        self.monthIncomeCents = monthIncomeCents
        self.monthBalanceCents = monthBalanceCents
        self.sparkline = sparkline
        self.trend7 = trend7 ?? Array(sparkline.suffix(7))
        self.monthNumber = monthNumber
        self.year = year
        self.average7Cents = average7Cents
        self.currencySymbol = currencySymbol
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthExpenseCents = try container.decodeIfPresent(Int.self, forKey: .monthExpenseCents) ?? 0
        monthIncomeCents = try container.decodeIfPresent(Int.self, forKey: .monthIncomeCents) ?? 0
        monthBalanceCents = try container.decodeIfPresent(Int.self, forKey: .monthBalanceCents) ?? 0
        sparkline = try container.decodeIfPresent([Double].self, forKey: .sparkline) ?? []
        trend7 = try container.decodeIfPresent([Double].self, forKey: .trend7) ?? Array(sparkline.suffix(7))
        monthNumber = try container.decodeIfPresent(Int.self, forKey: .monthNumber) ?? Calendar.current.component(.month, from: Date())
        year = try container.decodeIfPresent(Int.self, forKey: .year) ?? Calendar.current.component(.year, from: Date())
        average7Cents = try container.decodeIfPresent(Int.self, forKey: .average7Cents) ?? 0
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol) ?? MoneyFormatter.currencySymbol()
    }
}

struct WidgetSnapshot: Codable, Equatable {
    let updatedAt: Date
    let quickEntry: QuickEntryWidgetModel
    let summary: SummaryTrendWidgetModel

    init(
        updatedAt: Date,
        quickEntry: QuickEntryWidgetModel,
        summary: SummaryTrendWidgetModel
    ) {
        self.updatedAt = updatedAt
        self.quickEntry = quickEntry
        self.summary = summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        quickEntry = try container.decodeIfPresent(QuickEntryWidgetModel.self, forKey: .quickEntry)
            ?? WidgetSnapshot.placeholder.quickEntry
        summary = try container.decodeIfPresent(SummaryTrendWidgetModel.self, forKey: .summary)
            ?? WidgetSnapshot.placeholder.summary
    }

    func sanitized(for now: Date) -> WidgetSnapshot {
        let calendar = Calendar.current
        guard !calendar.isDate(updatedAt, inSameDayAs: now) else {
            return self
        }

        let previousDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
        let snapshotIsYesterday = previousDay.map { calendar.isDate(updatedAt, inSameDayAs: $0) } ?? false
        let sanitizedQuickEntry = QuickEntryWidgetModel(
            todayExpenseCents: 0,
            todayEntryCount: 0,
            yesterdayExpenseCents: snapshotIsYesterday ? quickEntry.todayExpenseCents : nil,
            currencySymbol: quickEntry.currencySymbol
        )

        let sameMonth = calendar.isDate(updatedAt, equalTo: now, toGranularity: .month)
        let sanitizedSummary: SummaryTrendWidgetModel
        if sameMonth {
            sanitizedSummary = summary
        } else {
            sanitizedSummary = SummaryTrendWidgetModel(
                monthExpenseCents: 0,
                monthIncomeCents: 0,
                monthBalanceCents: 0,
                sparkline: [],
                trend7: [],
                monthNumber: calendar.component(.month, from: now),
                year: calendar.component(.year, from: now),
                average7Cents: 0,
                currencySymbol: summary.currencySymbol
            )
        }

        return WidgetSnapshot(
            updatedAt: updatedAt,
            quickEntry: sanitizedQuickEntry,
            summary: sanitizedSummary
        )
    }

    static let placeholder = WidgetSnapshot(
        updatedAt: Date(),
        quickEntry: QuickEntryWidgetModel(
            todayExpenseCents: 0,
            todayEntryCount: 0,
            yesterdayExpenseCents: nil,
            currencySymbol: MoneyFormatter.currencySymbol()
        ),
        summary: SummaryTrendWidgetModel(
            monthExpenseCents: 0,
            monthIncomeCents: 0,
            monthBalanceCents: 0,
            sparkline: [0.2, 0.3, 0.15, 0.4, 0.25, 0.35, 0.2],
            trend7: [0.2, 0.3, 0.15, 0.4, 0.25, 0.35, 0.2],
            monthNumber: Calendar.current.component(.month, from: Date()),
            year: Calendar.current.component(.year, from: Date()),
            average7Cents: 0,
            currencySymbol: MoneyFormatter.currencySymbol()
        )
    )
}

enum WidgetKind {
    static let quickEntry = "TallyQuickEntryWidget"
    static let summaryTrend = "TallySummaryTrendWidget"
}

enum WidgetDataStore {
    static let appGroupId = "group.com.langya.Tally"
    private static let snapshotKey = "tally.widget.snapshot"
    private static let logger = Logger(subsystem: "com.langya.Tally", category: "appgroup")
    private static var didLogFailure = false

    static func loadSnapshot() -> WidgetSnapshot {
        guard let data = sharedDefaults()?.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .placeholder
        }
        return snapshot
    }

    static func saveSnapshot(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        sharedDefaults()?.set(data, forKey: snapshotKey)
    }

    private static func sharedDefaults() -> UserDefaults? {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            if !didLogFailure {
                logger.fault("App Group \(appGroupId, privacy: .public) unavailable - shared data disabled")
                didLogFailure = true
            }
            return nil
        }
        return defaults
    }
}
