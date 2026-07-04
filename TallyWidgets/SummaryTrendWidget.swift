import WidgetKit
import SwiftUI

struct SummaryTrendProvider: TimelineProvider {
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
        let next = WidgetTimelineRefresh.next(after: now, interval: 60 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct SummaryTrendWidget: Widget {
    static let kind = WidgetKind.summaryTrend

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SummaryTrendProvider()) { entry in
            SummaryTrendWidgetView(model: entry.snapshot.summary)
        }
        .configurationDisplayName(TallyLocalization.text("summary_trend_widget_name", locale: TallyLocalization.widgetLocale))
        .description(TallyLocalization.text("summary_trend_widget_description", locale: TallyLocalization.widgetLocale))
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
