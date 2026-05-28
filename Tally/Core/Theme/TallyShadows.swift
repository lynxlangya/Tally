import SwiftUI

enum TallyShadows {
    enum Style {
        case shadow1
        case shadow2
        case shadowFab
    }

    static let shadow1 = Style.shadow1
    static let shadow2 = Style.shadow2
    static let shadowFab = Style.shadowFab
}

extension View {
    func tallyShadow(_ style: TallyShadows.Style) -> some View {
        modifier(TallyShadowModifier(style: style))
    }
}

private struct TallyShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tallyThemeColors) private var themeColors

    let style: TallyShadows.Style

    func body(content: Content) -> some View {
        let layers = style.layers(for: colorScheme, themeColors: themeColors)
        return layers.reduce(AnyView(content)) { view, layer in
            AnyView(
                view.shadow(
                    color: layer.color,
                    radius: layer.radius,
                    x: layer.x,
                    y: layer.y
                )
            )
        }
    }
}

private struct TallyShadowLayer {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

private extension TallyShadows.Style {
    func layers(for colorScheme: ColorScheme, themeColors: TallyThemeColors) -> [TallyShadowLayer] {
        switch (self, colorScheme) {
        case (.shadow1, .dark):
            return [
                TallyShadowLayer(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
            ]
        case (.shadow1, _):
            return [
                TallyShadowLayer(color: Color.tallyInk.opacity(0.06), radius: 2, x: 0, y: 1)
            ]
        case (.shadow2, .dark):
            return [
                TallyShadowLayer(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 4),
                TallyShadowLayer(color: Color.white.opacity(0.06), radius: 0.5, x: 0, y: 0)
            ]
        case (.shadow2, _):
            return [
                TallyShadowLayer(color: Color.tallyInkDim.opacity(0.08), radius: 18, x: 0, y: 4),
                TallyShadowLayer(color: Color.tallyInk.opacity(0.05), radius: 0.5, x: 0, y: 0)
            ]
        case (.shadowFab, .dark):
            return [
                TallyShadowLayer(color: themeColors.accent.opacity(0.45), radius: 32, x: 0, y: 12),
                TallyShadowLayer(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 4)
            ]
        case (.shadowFab, _):
            return [
                TallyShadowLayer(color: themeColors.accent.opacity(0.35), radius: 32, x: 0, y: 12),
                TallyShadowLayer(color: themeColors.accentLo.opacity(0.18), radius: 12, x: 0, y: 4)
            ]
        }
    }
}
