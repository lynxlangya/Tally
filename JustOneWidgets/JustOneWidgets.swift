import WidgetKit
import SwiftUI

@main
struct JustOneWidgetsBundle: WidgetBundle {
    var body: some Widget {
        QuickEntryWidget()
        SummaryTrendWidget()
    }
}
