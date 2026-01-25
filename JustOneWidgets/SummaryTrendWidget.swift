import WidgetKit
import SwiftUI

struct SummaryTrendProvider: TimelineProvider {
    func placeholder(in context: Context) -> JustOneWidgetEntry {
        JustOneWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (JustOneWidgetEntry) -> Void) {
        let snapshot = WidgetDataStore.loadSnapshot()
        completion(JustOneWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JustOneWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.loadSnapshot()
        let entry = JustOneWidgetEntry(date: Date(), snapshot: snapshot)
        let next = Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct SummaryTrendWidget: Widget {
    static let kind = WidgetKind.summaryTrend

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SummaryTrendProvider()) { entry in
            SummaryTrendWidgetView(model: entry.snapshot.summary)
        }
        .configurationDisplayName("本月概览")
        .description("查看本月结余与趋势")
        .supportedFamilies([.systemMedium])
    }
}
