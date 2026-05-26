import SwiftUI

struct JOShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum JOShadows {
    static let card = JOShadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    static let floating = JOShadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 10)
}
