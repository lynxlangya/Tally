import SwiftUI

struct LegacyShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum LegacyShadows {
    static let card = LegacyShadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    static let floating = LegacyShadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 10)
}
