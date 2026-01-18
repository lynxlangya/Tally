import SwiftUI

struct JOSheetContainer<Content: View>: View {
    let cornerRadius: CGFloat
    let background: Color
    let borderOpacity: Double
    let borderColor: Color
    let content: Content

    init(
        cornerRadius: CGFloat,
        background: Color,
        borderOpacity: Double = 0,
        borderColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.background = background
        self.borderOpacity = borderOpacity
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor.opacity(borderOpacity), lineWidth: 1)
            )
    }
}
