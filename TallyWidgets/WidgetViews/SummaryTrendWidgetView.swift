import SwiftUI
import WidgetKit

struct SummaryTrendWidgetView: View {
    let model: SummaryTrendWidgetModel

    var body: some View {
        SummaryTrendWidgetCard(model: model)
        .widgetURL(URL(string: "tally://home"))
        .joWidgetBackground()
    }
}
