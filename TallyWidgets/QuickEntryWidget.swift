import WidgetKit
import SwiftUI

struct TallyWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct QuickEntryProvider: TimelineProvider {
    func placeholder(in context: Context) -> TallyWidgetEntry {
        TallyWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TallyWidgetEntry) -> Void) {
        let now = Date()
        let snapshot = WidgetDataStore.loadSnapshot().sanitized(for: now)
        completion(TallyWidgetEntry(date: now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TallyWidgetEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetDataStore.loadSnapshot().sanitized(for: now)
        let entry = TallyWidgetEntry(date: now, snapshot: snapshot)
        let next = WidgetTimelineRefresh.next(after: now, interval: 30 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

enum WidgetTimelineRefresh {
    static func next(after now: Date, interval: TimeInterval) -> Date {
        let intervalDate = now.addingTimeInterval(interval)
        let calendar = Calendar.current
        let nextDayStart = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? intervalDate
        let afterMidnight = calendar.date(byAdding: .minute, value: 5, to: nextDayStart) ?? nextDayStart.addingTimeInterval(5 * 60)
        return min(intervalDate, afterMidnight)
    }
}

struct QuickEntryWidget: Widget {
    static let kind = WidgetKind.quickEntry

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: QuickEntryProvider()) { entry in
            QuickEntryWidgetView(model: entry.snapshot.quickEntry)
        }
        .configurationDisplayName(TallyLocalization.text("quick_entry_widget_name", locale: TallyLocalization.widgetLocale))
        .description(TallyLocalization.text("quick_entry_widget_description", locale: TallyLocalization.widgetLocale))
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}
