import SwiftUI

struct TallyThemeColors {
    let accent: Color
    let accentInk: Color
    let accentTint: Color
    let accentLo: Color

    static let fallback = TallyThemeColors(
        accent: .tallyAccent,
        accentInk: .tallyAccentInk,
        accentTint: .tallyAccentTint,
        accentLo: .tallyAccentLo
    )

    init(accent: AccentOption) {
        self.accent = accent.color
        self.accentInk = accent.foregroundColor
        self.accentTint = accent.color.opacity(0.14)
        self.accentLo = accent.color.opacity(0.22)
    }

    private init(accent: Color, accentInk: Color, accentTint: Color, accentLo: Color) {
        self.accent = accent
        self.accentInk = accentInk
        self.accentTint = accentTint
        self.accentLo = accentLo
    }
}

private struct TallyThemeColorsKey: EnvironmentKey {
    static let defaultValue = TallyThemeColors.fallback
}

extension EnvironmentValues {
    var tallyThemeColors: TallyThemeColors {
        get { self[TallyThemeColorsKey.self] }
        set { self[TallyThemeColorsKey.self] = newValue }
    }

    var tallyAccent: Color {
        tallyThemeColors.accent
    }

    var tallyAccentInk: Color {
        tallyThemeColors.accentInk
    }

    var tallyAccentTint: Color {
        tallyThemeColors.accentTint
    }

    var tallyAccentLo: Color {
        tallyThemeColors.accentLo
    }
}
