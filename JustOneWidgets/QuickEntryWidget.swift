import WidgetKit
import SwiftUI

struct JustOneWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct QuickEntryProvider: TimelineProvider {
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
        let next = Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct QuickEntryWidget: Widget {
    static let kind = WidgetKind.quickEntry

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: QuickEntryProvider()) { entry in
            QuickEntryWidgetView(model: entry.snapshot.quickEntry)
        }
        .configurationDisplayName("快速记账")
        .description("查看今日支出并快速记账")
        .supportedFamilies([.systemSmall])
    }
}
