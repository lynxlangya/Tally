import SwiftUI
import WidgetKit

extension View {
    @ViewBuilder
    func joWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(WidgetTheme.background, for: .widget)
        } else {
            self.background(WidgetTheme.background)
        }
    }
}
