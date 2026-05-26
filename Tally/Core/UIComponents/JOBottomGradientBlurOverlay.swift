import SwiftUI

struct JOBottomGradientBlurOverlay: View {
    var height: CGFloat = 120
    var maxOpacity: Double = 0.7

    var body: some View {
        ZStack {
            Rectangle()
                .fill(JOColors.background.opacity(maxOpacity))
                .blur(radius: 12)
            LinearGradient(
                colors: [
                    JOColors.background.opacity(maxOpacity),
                    JOColors.background.opacity(0)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        .mask(
            LinearGradient(
                colors: [
                    Color.black,
                    Color.black.opacity(0)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        JOColors.background.ignoresSafeArea()
        JOBottomGradientBlurOverlay(height: 160)
    }
}
