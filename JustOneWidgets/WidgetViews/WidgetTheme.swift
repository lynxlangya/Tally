import SwiftUI
import WidgetKit

enum WidgetTheme {
    static let background = Color(red: 16 / 255, green: 34 / 255, blue: 19 / 255)
    static let surface = Color(red: 22 / 255, green: 43 / 255, blue: 26 / 255)
    static let accent = Color(red: 19 / 255, green: 236 / 255, blue: 55 / 255)
    static let accentForeground = Color(red: 16 / 255, green: 34 / 255, blue: 19 / 255)
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color(red: 146 / 255, green: 201 / 255, blue: 155 / 255).opacity(0.85)
    static let border = Color.white.opacity(0.08)
}

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
