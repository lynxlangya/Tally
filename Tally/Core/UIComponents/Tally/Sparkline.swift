import SwiftUI

struct Sparkline: View {
    let data: [Double]
    let color: Color
    let fill: Bool
    let dot: Bool
    let dotIndex: Int?
    let baseline: Bool
    let width: CGFloat
    let height: CGFloat

    init(
        data: [Double],
        color: Color = .tallyAccent,
        fill: Bool = true,
        dot: Bool = true,
        dotIndex: Int? = nil,
        baseline: Bool = false,
        width: CGFloat,
        height: CGFloat
    ) {
        self.data = data
        self.color = color
        self.fill = fill
        self.dot = dot
        self.dotIndex = dotIndex
        self.baseline = baseline
        self.width = width
        self.height = height
    }

    var body: some View {
        let points = points(in: CGSize(width: width, height: height))

        ZStack {
            if points.count >= 2 {
                if fill {
                    fillPath(points: points)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.22), color.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                if baseline {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height - 4))
                        path.addLine(to: CGPoint(x: width, y: height - 4))
                    }
                    .stroke(Color.tallyLine, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }

                linePath(points: points)
                    .stroke(color, style: StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round))

                if dot, let point = pointForDot(in: points) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.tallyBg, lineWidth: 2)
                        )
                        .position(point)
                }
            }
        }
        .frame(width: width, height: height)
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

    private func fillPath(points: [CGPoint]) -> Path {
        var path = linePath(points: points)
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }

    private func pointForDot(in points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let index = dotIndex ?? points.count - 1
        guard points.indices.contains(index) else { return nil }
        return points[index]
    }
}

#Preview("Sparkline Light") {
    SparklinePreview()
        .preferredColorScheme(.light)
}

#Preview("Sparkline Dark") {
    SparklinePreview()
        .preferredColorScheme(.dark)
}

private struct SparklinePreview: View {
    var body: some View {
        VStack(spacing: TallySpacing.s6) {
            Sparkline(data: [3, 8], baseline: true, width: 260, height: 56)
            Sparkline(data: [2, 5, 4, 9, 7, 12, 8], color: .catTeal, width: 260, height: 56)
            Sparkline(data: (0..<30).map { Double(($0 * 7) % 17) }, color: .catPlum, dotIndex: 12, width: 260, height: 64)
        }
        .padding()
        .background(Color.tallyBg)
    }
}
