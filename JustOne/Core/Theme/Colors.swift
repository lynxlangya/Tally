import SwiftUI
import UIKit

enum JOColors {
    static var background: Color {
        dynamic(light: rgb(246, 248, 246), dark: rgb(16, 34, 19))
    }

    static var surface: Color {
        dynamic(light: rgb(255, 255, 255), dark: rgb(22, 43, 26))
    }

    static var textPrimary: Color {
        dynamic(light: rgb(15, 23, 16), dark: rgb(243, 247, 244))
    }

    static var textSecondary: Color {
        dynamic(light: rgb(107, 114, 128), dark: rgb(146, 201, 155))
    }

    static var divider: Color {
        dynamic(light: rgb(229, 231, 235), dark: UIColor(white: 1.0, alpha: 0.12))
    }

    static let accent = Color(red: 19 / 255, green: 236 / 255, blue: 55 / 255)
    static let accentForeground = Color(red: 16 / 255, green: 34 / 255, blue: 19 / 255)

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
}
