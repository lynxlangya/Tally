import SwiftUI

struct JOCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(JOSpacing.lg)
            .background(JOColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: JORadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: JORadius.card, style: .continuous)
                    .stroke(JOColors.divider, lineWidth: 1)
            )
            .shadow(
                color: JOShadows.card.color,
                radius: JOShadows.card.radius,
                x: JOShadows.card.x,
                y: JOShadows.card.y
            )
    }
}
