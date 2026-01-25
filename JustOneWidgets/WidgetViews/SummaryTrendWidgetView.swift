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

                sparklineView

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
        .widgetURL(URL(string: "justone://home"))
        .joWidgetBackground()
    }

    private var sparklineView: some View {
        let values = model.sparkline.isEmpty ? WidgetSnapshot.placeholder.summary.sparkline : model.sparkline
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(values.indices, id: \.self) { index in
                Capsule()
                    .fill(index == values.indices.last ? WidgetTheme.accent : WidgetTheme.textSecondary.opacity(0.5))
                    .frame(width: 10, height: max(6, values[index] * 36))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
