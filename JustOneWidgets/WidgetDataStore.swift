import Foundation

struct QuickEntryWidgetModel: Codable, Equatable {
    let todayExpenseCents: Int
    let currencySymbol: String
}

struct SummaryTrendWidgetModel: Codable, Equatable {
    let monthExpenseCents: Int
    let monthIncomeCents: Int
    let monthBalanceCents: Int
    let sparkline: [Double]
}

struct WidgetSnapshot: Codable, Equatable {
    let updatedAt: Date
    let quickEntry: QuickEntryWidgetModel
    let summary: SummaryTrendWidgetModel

    static let placeholder = WidgetSnapshot(
        updatedAt: Date(),
        quickEntry: QuickEntryWidgetModel(todayExpenseCents: 0, currencySymbol: "¥"),
        summary: SummaryTrendWidgetModel(
            monthExpenseCents: 0,
            monthIncomeCents: 0,
            monthBalanceCents: 0,
            sparkline: [0.2, 0.3, 0.15, 0.4, 0.25, 0.35, 0.2]
        )
    )
}

enum WidgetKind {
    static let quickEntry = "JustOneQuickEntryWidget"
    static let summaryTrend = "JustOneSummaryTrendWidget"
}

enum WidgetDataStore {
    static let appGroupId = "group.com.langya.JustOne"
    private static let snapshotKey = "justone.widget.snapshot"

    static func loadSnapshot() -> WidgetSnapshot {
        guard let data = sharedDefaults()?.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .placeholder
        }
        return snapshot
    }

    private static func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }
}
