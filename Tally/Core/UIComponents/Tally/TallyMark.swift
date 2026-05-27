import SwiftUI

struct TallyMark: View {
    enum Variant {
        case one
        case five
    }

    let size: CGFloat
    let variant: Variant
    let color: Color
    let strokeWidth: CGFloat?

    init(
        size: CGFloat,
        variant: Variant,
        color: Color = .tallyInk,
        strokeWidth: CGFloat? = nil
    ) {
        self.size = size
        self.variant = variant
        self.color = color
        self.strokeWidth = strokeWidth
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scaleX = canvasSize.width / 24
            let scaleY = canvasSize.height / 24
            let width = strokeWidth ?? max(2, size * 0.12)

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * scaleX, y: y * scaleY)
            }

            func drawLine(from start: CGPoint, to end: CGPoint) {
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                )
            }

            switch variant {
            case .one:
                drawLine(from: point(12, 4), to: point(12, 20))
            case .five:
                drawLine(from: point(4.5, 4), to: point(4.5, 20))
                drawLine(from: point(9, 4), to: point(9, 20))
                drawLine(from: point(13.5, 4), to: point(13.5, 20))
                drawLine(from: point(18, 4), to: point(18, 20))
                drawLine(from: point(2, 20), to: point(21, 4))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("TallyMark Light") {
    HStack(spacing: TallySpacing.s6) {
        TallyMark(size: 32, variant: .one)
        TallyMark(size: 40, variant: .five, color: .tallyAccent)
    }
    .padding()
    .background(Color.tallyBg)
    .preferredColorScheme(.light)
}

#Preview("TallyMark Dark") {
    HStack(spacing: TallySpacing.s6) {
        TallyMark(size: 32, variant: .one)
        TallyMark(size: 40, variant: .five, color: .tallyAccent)
    }
    .padding()
    .background(Color.tallyBg)
    .preferredColorScheme(.dark)
}
