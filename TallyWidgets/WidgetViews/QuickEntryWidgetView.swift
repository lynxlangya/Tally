import SwiftUI
import WidgetKit

struct QuickEntryWidgetView: View {
    let model: QuickEntryWidgetModel

    var body: some View {
        QuickEntryWidgetCard(model: model)
        .widgetURL(URL(string: "tally://quickEntry"))
        .joWidgetBackground()
    }
}
