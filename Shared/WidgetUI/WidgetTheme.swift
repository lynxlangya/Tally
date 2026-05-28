import Foundation
import SwiftUI

enum WidgetTheme {
    static let background = Color("tallyBg")
    static let surface = Color("tallySurface")
    static let surface2 = Color("tallySurface2")
    static let accent = Color("tallyAccent")
    static let accentTint = Color("tallyAccentTint")
    static let accentForeground = Color("tallyAccentInk")
    static let textPrimary = Color("tallyInk")
    static let textSecondary = Color("tallyInkDim")
    static let textFaint = Color("tallyInkFaint")
    static let border = Color("tallyLine")

    static func amountText(
        cents: Int,
        size: CGFloat,
        weight: Font.Weight = .medium,
        color: Color = textPrimary,
        showYen: Bool = true
    ) -> some View {
        let parts = MoneyFormatter.parts(fromCents: cents)
        let decimalSize = size * 0.62

        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            if showYen {
                Text("¥")
                    .font(.system(size: decimalSize, weight: .light, design: .rounded))
                    .foregroundColor(color.opacity(0.55))
                    .baselineOffset(-size * 0.06)
            }

            Text(parts.integer)
                .font(.system(size: size, weight: weight, design: .rounded))
                .foregroundColor(color)

            Text(".\(parts.decimal)")
                .font(.system(size: decimalSize, weight: weight, design: .rounded))
                .foregroundColor(color.opacity(0.5))
        }
    }

    static func compactMoney(cents: Int) -> String {
        MoneyFormatter.compactString(fromCents: cents)
    }
}

struct WidgetTallyMark: View {
    enum Variant {
        case one
        case five
    }

    let variant: Variant
    let size: CGFloat
    let color: Color
    let strokeWidth: CGFloat?

    init(
        variant: Variant,
        size: CGFloat,
        color: Color = WidgetTheme.textPrimary,
        strokeWidth: CGFloat? = nil
    ) {
        self.variant = variant
        self.size = size
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

struct WidgetSparkline: View {
    let data: [Double]
    let height: CGFloat
    let fill: Bool
    let dot: Bool
    let baseline: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = CGSize(width: proxy.size.width, height: height)
            let points = points(in: size)
            ZStack {
                if baseline {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: size.height - 4))
                        path.addLine(to: CGPoint(x: size.width, y: size.height - 4))
                    }
                    .stroke(WidgetTheme.border.opacity(0.9), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }

                if points.count >= 2 {
                    if fill {
                        fillPath(points: points, size: size)
                            .fill(
                                LinearGradient(
                                    colors: [WidgetTheme.accent.opacity(0.24), WidgetTheme.accent.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    linePath(points: points)
                        .stroke(WidgetTheme.accent, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

                    if dot, let last = points.last {
                        Circle()
                            .fill(WidgetTheme.accent)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(WidgetTheme.surface, lineWidth: 2))
                            .position(last)
                    }
                }
            }
        }
        .frame(height: height)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard data.count >= 2 else { return [] }
        let minValue = min(data.min() ?? 0, 0)
        let maxValue = max(data.max() ?? 1, 1)
        let range = max(maxValue - minValue, 1)
        let stepX = size.width / CGFloat(data.count - 1)
        return data.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * stepX,
                y: size.height - CGFloat((value - minValue) / range) * (size.height - 8) - 4
            )
        }
    }

    private func linePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(
                x: (previous.x + current.x) / 2,
                y: (previous.y + current.y) / 2
            )
            path.addQuadCurve(to: midpoint, control: previous)
        }

        if let last = points.last {
            path.addQuadCurve(to: last, control: last)
        }

        return path
    }

    private func fillPath(points: [CGPoint], size: CGSize) -> Path {
        var path = linePath(points: points)
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }
}
