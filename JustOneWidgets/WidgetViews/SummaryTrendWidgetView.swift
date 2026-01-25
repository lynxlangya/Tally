import SwiftUI
import WidgetKit

struct SummaryTrendWidgetView: View {
    let model: SummaryTrendWidgetModel

    private var monthMarkers: [Int] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: Date()) else { return [1, 5, 10, 15, 20, 25, 30] }
        let maxDay = range.upperBound - 1
        var markers = [1, 5, 10, 15, 20, 25]
        if !markers.contains(maxDay) {
            markers.append(maxDay)
        } else {
            // 若 maxDay 恰好是 25/20 等，仍保持最后一个是当月最后一天
            if markers.last != maxDay {
                markers.append(maxDay)
            }
        }
        return markers
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(WidgetTheme.surface.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(WidgetTheme.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("本月结余")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(WidgetTheme.textSecondary)
                        Text(formatCurrency(cents: model.monthBalanceCents))
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(WidgetTheme.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Circle()
                            .fill(WidgetTheme.surface.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(WidgetTheme.textSecondary)
                            )
                        Link(destination: URL(string: "justone://quickEntry")!) {
                            Circle()
                                .fill(WidgetTheme.accent)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(WidgetTheme.accentForeground)
                                )
                        }
                    }
                }

                LineChart(values: model.sparkline)
                    .frame(height: 56)

                HStack {
                    ForEach(monthMarkers, id: \.self) { day in
                        Text("\(day)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(WidgetTheme.textSecondary.opacity(0.7))
                        if day != monthMarkers.last {
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "justone://home"))
        .joWidgetBackground()
    }

    private func formatCurrency(cents: Int) -> String {
        let value = Decimal(cents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let number = formatter.string(from: value as NSDecimalNumber) ?? "0.00"
        return "¥\(number)"
    }
}

private struct LineChart: View {
    let values: [Double]

    private var normalizedValues: [Double] {
        let source = values.isEmpty ? WidgetSnapshot.placeholder.summary.sparkline : values
        let maxValue = source.max() ?? 1
        if maxValue <= 0 { return source.map { _ in 0 } }
        return source.map { $0 / maxValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let points = buildPoints(size: proxy.size)
            ZStack {
                if points.count > 1 {
                    let linePath = smoothPath(points: points)
                    let fillPath = areaPath(linePath: linePath, size: proxy.size)

                    fillPath
                        .fill(
                            LinearGradient(
                                colors: [
                                    WidgetTheme.accent.opacity(0.25),
                                    WidgetTheme.accent.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    linePath
                        .stroke(WidgetTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }

                if let last = points.last {
                    Circle()
                        .fill(WidgetTheme.accent)
                        .frame(width: 8, height: 8)
                        .position(last)
                }
            }
        }
    }

    private func smoothPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        path.move(to: points[0])
        for index in 1..<points.count {
            let prev = points[index - 1]
            let current = points[index]
            let mid = CGPoint(x: (prev.x + current.x) / 2, y: (prev.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: prev)
            if index == points.count - 1 {
                path.addQuadCurve(to: current, control: current)
            }
        }
        return path
    }

    private func areaPath(linePath: Path, size: CGSize) -> Path {
        var path = linePath
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }

    private func buildPoints(size: CGSize) -> [CGPoint] {
        let values = normalizedValues
        guard values.count > 1 else { return [] }
        let stepX = size.width / CGFloat(values.count - 1)
        let minY: CGFloat = 8
        let maxY = size.height - 8
        return values.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            let y = maxY - (maxY - minY) * CGFloat(value)
            return CGPoint(x: x, y: y)
        }
    }
}
