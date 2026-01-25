import SwiftUI
import WidgetKit

struct SummaryTrendWidgetView: View {
    let model: SummaryTrendWidgetModel

    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

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

                HStack(spacing: 10) {
                    ForEach(weekdays.indices, id: \.self) { index in
                        Text(weekdays[index])
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isToday(index: index) ? WidgetTheme.accent : WidgetTheme.textSecondary.opacity(0.7))
                    }
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "justone://home"))
        .joWidgetBackground()
    }

    private func isToday(index: Int) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar: 1=Sunday ... 7=Saturday. We map to Mon=0.
        let mapped = (weekday + 5) % 7
        return index == mapped
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
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    points.dropFirst().forEach { path.addLine(to: $0) }
                }
                .stroke(WidgetTheme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                if let last = points.last {
                    Circle()
                        .fill(WidgetTheme.accent)
                        .frame(width: 8, height: 8)
                        .position(last)
                }
            }
        }
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
