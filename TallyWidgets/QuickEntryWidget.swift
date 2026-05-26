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
        let snapshot = WidgetDataStore.loadSnapshot()
        completion(TallyWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TallyWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.loadSnapshot()
        let entry = TallyWidgetEntry(date: Date(), snapshot: snapshot)
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
        .contentMarginsDisabled()
    }
}
