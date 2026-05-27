import SwiftUI
import UIKit

struct CategoryTile: View {
    enum Fill {
        case soft
        case solid
    }

    let iconName: String
    let color: Color
    let size: CGFloat
    let radius: CGFloat
    let filled: Fill

    init(
        iconName: String,
        color: Color,
        size: CGFloat = 36,
        radius: CGFloat = TallyRadii.md,
        filled: Fill = .soft
    ) {
        self.iconName = iconName
        self.color = color
        self.size = size
        self.radius = radius
        self.filled = filled
    }

    var body: some View {
        Image(systemName: resolvedSystemName)
            .font(.system(size: round(size * 0.5), weight: .semibold))
            .foregroundStyle(filled == .solid ? Color.tallyAccentInk : color)
            .frame(width: size, height: size)
            .background(filled == .solid ? color : color.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(alignment: .bottom) {
                if filled == .solid {
                    Rectangle()
                        .fill(Color.black.opacity(0.18))
                        .frame(height: 1)
                        .padding(.horizontal, 1)
                }
            }
            .accessibilityHidden(true)
    }

    private var resolvedSystemName: String {
        UIImage(systemName: iconName) == nil ? "questionmark" : iconName
    }
}

#Preview("CategoryTile Light") {
    CategoryTilePreview()
        .preferredColorScheme(.light)
}

#Preview("CategoryTile Dark") {
    CategoryTilePreview()
        .preferredColorScheme(.dark)
}

private struct CategoryTilePreview: View {
    var body: some View {
        HStack(spacing: TallySpacing.s4) {
            CategoryTile(iconName: "fork.knife", color: .catTerracotta)
            CategoryTile(iconName: "cart.fill", color: .catTeal, filled: .solid)
            CategoryTile(iconName: "missing", color: .catAsh, size: 48, radius: TallyRadii.lg)
        }
        .padding()
        .background(Color.tallyBg)
    }
}
