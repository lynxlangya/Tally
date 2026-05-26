import SwiftUI

struct JOSheetHandle: View {
    let width: CGFloat
    let height: CGFloat
    let opacity: Double

    init(width: CGFloat = 40, height: CGFloat = 6, opacity: Double = 0.3) {
        self.width = width
        self.height = height
        self.opacity = opacity
    }

    var body: some View {
        Capsule()
            .fill(Color.white.opacity(opacity))
            .frame(width: width, height: height)
    }
}
