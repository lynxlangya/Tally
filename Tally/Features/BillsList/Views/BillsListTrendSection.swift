import SwiftUI

struct BillsListTrendSection: View {
    let points: [Double]
    let highlightIndex: Int?
    let valuesCents: [Int]
    let axisLabels: [String]
    @Binding var activeIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: LegacySpacing.md) {
            TrendChartView(
                points: points,
                highlightIndex: highlightIndex,
                valuesCents: valuesCents,
                activeIndex: $activeIndex
            )
            .frame(height: BillsListLayout.trendHeight)

            AxisLabelsView(labels: axisLabels)
        }
    }
}

private struct TrendChartView: View {
    let points: [Double]
    let highlightIndex: Int?
    let valuesCents: [Int]
    @Binding var activeIndex: Int?

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let safePoints = points.isEmpty ? [0, 0, 0, 0, 0, 0, 0] : points
            let step = safePoints.count > 1 ? width / CGFloat(safePoints.count - 1) : width
            let displayIndex = activeIndex ?? highlightIndex

            ZStack {
                ChartGridView()

                if safePoints.count > 1 {
                    TrendFillPath(points: safePoints, step: step, height: height)
                        .fill(
                            LinearGradient(
                                colors: [LegacyColors.accent.opacity(0.35), LegacyColors.accent.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    TrendLinePath(points: safePoints, step: step, height: height)
                        .stroke(
                            LegacyColors.accent.opacity(0.9),
                            style: StrokeStyle(
                                lineWidth: BillsListLayout.trendLineWidth,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .shadow(color: LegacyColors.accent.opacity(0.2), radius: 6, x: 0, y: 0)

                    if let displayIndex,
                       safePoints.indices.contains(displayIndex) {
                        let x = step * CGFloat(displayIndex)
                        let y = height - CGFloat(safePoints[displayIndex]) * height
                        Circle()
                            .fill(LegacyColors.accent)
                            .frame(width: BillsListLayout.trendDotSize, height: BillsListLayout.trendDotSize)
                            .overlay(
                                Circle()
                                    .stroke(LegacyColors.background, lineWidth: BillsListLayout.trendDotStroke)
                            )
                            .position(x: x, y: y)

                        if valuesCents.indices.contains(displayIndex) {
                            let valueText = MoneyFormatter.string(fromCents: valuesCents[displayIndex])
                            Text(valueText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(LegacyColors.surface)
                                .clipShape(Capsule())
                                .position(
                                    x: x,
                                    y: max(y - BillsListLayout.trendTooltipOffset, BillsListLayout.trendTooltipMinY)
                                )
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let rawIndex = Int(round(value.location.x / max(step, 1)))
                        let clamped = min(max(rawIndex, 0), safePoints.count - 1)
                        activeIndex = clamped
                    }
                    .onEnded { _ in
                        activeIndex = nil
                    }
            )
        }
    }
}

private struct TrendLinePath: Shape {
    let points: [Double]
    let step: CGFloat
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        let positions = points.enumerated().map { index, value in
            CGPoint(x: step * CGFloat(index), y: height - CGFloat(value) * height)
        }
        return TrendPathBuilder.smoothPath(for: positions)
    }
}

private struct TrendFillPath: Shape {
    let points: [Double]
    let step: CGFloat
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }

        let positions = points.enumerated().map { index, value in
            CGPoint(x: step * CGFloat(index), y: height - CGFloat(value) * height)
        }

        var path = TrendPathBuilder.smoothPath(for: positions)
        path.addLine(to: CGPoint(x: step * CGFloat(points.count - 1), y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

private enum TrendPathBuilder {
    static func smoothPath(for points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        path.move(to: points[0])
        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        var previous = points[0]
        for index in 1..<points.count {
            let current = points[index]
            let mid = CGPoint(x: (previous.x + current.x) * 0.5, y: (previous.y + current.y) * 0.5)
            path.addQuadCurve(to: mid, control: previous)
            previous = current
        }
        if let last = points.last {
            path.addQuadCurve(to: last, control: previous)
        }
        return path
    }
}

private struct ChartGridView: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                if index < 3 {
                    Divider()
                        .overlay(LegacyColors.textSecondary.opacity(0.2))
                        .overlay(
                            Rectangle()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(LegacyColors.textSecondary.opacity(0.2))
                        )
                } else {
                    Color.clear
                        .frame(height: 1)
                }
                Spacer()
            }
        }
    }
}

private struct AxisLabelsView: View {
    let labels: [String]

    var body: some View {
        if labels.count <= 3 {
            HStack {
                if labels.indices.contains(0) {
                    Text(labels[0])
                }
                Spacer()
                if labels.indices.contains(1) {
                    Text(labels[1])
                }
                Spacer()
                if labels.indices.contains(2) {
                    Text(labels[2])
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(LegacyColors.textSecondary)
        } else {
            HStack(spacing: 0) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(LegacyColors.textSecondary)
        }
    }
}
