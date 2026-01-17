import SwiftUI
import UIKit

enum JOTheme {
    enum Mode {
        case system
        case dark
        case light
    }

    static var mode: Mode = .dark
}

enum JOColors {
    private enum Palette {
        static let primary = rgb(19, 236, 55)
        static let backgroundLight = rgb(246, 248, 246)
        static let backgroundDark = rgb(16, 34, 19)
        static let surfaceLight = rgb(255, 255, 255)
        static let surfaceDark = rgb(22, 43, 26)
        static let textLight = rgb(15, 23, 16)
        static let textDark = rgb(243, 247, 244)
        static let textSecondaryLight = rgb(107, 114, 128)
        static let textSecondaryDark = rgb(146, 201, 155)
    }

    static var background: Color {
        themed(light: Palette.backgroundLight, dark: Palette.backgroundDark)
    }

    static var surface: Color {
        themed(light: Palette.surfaceLight, dark: Palette.surfaceDark)
    }

    static var textPrimary: Color {
        themed(light: Palette.textLight, dark: Palette.textDark)
    }

    static var textSecondary: Color {
        themed(light: Palette.textSecondaryLight, dark: Palette.textSecondaryDark)
    }

    static var divider: Color {
        themed(light: rgb(229, 231, 235), dark: UIColor(white: 1.0, alpha: 0.12))
    }

    static let primary = Color(Palette.primary)
    static let accent = primary
    static let accentForeground = Color(Palette.backgroundDark)
    static let tabBarBackground = Color(Palette.surfaceDark).opacity(0.88)
    static let tabBarBorder = Color.white.opacity(0.06)
    static let tabIconMuted = Color(Palette.textSecondaryDark).opacity(0.6)
    static let fabGreen = primary
    static let fabIcon = Color(Palette.backgroundDark)
    static let fabGlow = primary

    private static func themed(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traitCollection in
            switch JOTheme.mode {
            case .system:
                return traitCollection.userInterfaceStyle == .dark ? dark : light
            case .dark:
                return dark
            case .light:
                return light
            }
        })
    }

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
}
