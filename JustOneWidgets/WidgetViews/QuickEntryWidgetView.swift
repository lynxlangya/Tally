import SwiftUI
import WidgetKit

struct QuickEntryWidgetView: View {
    let model: QuickEntryWidgetModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(WidgetTheme.surface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(WidgetTheme.border, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetTheme.textSecondary)
                    Text("今日支出")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }

                Text(formatCurrency(cents: model.todayExpenseCents, symbol: model.currencySymbol))
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textPrimary)

                Capsule()
                    .fill(WidgetTheme.accent)
                    .frame(width: 36, height: 4)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    Link(destination: URL(string: "justone://quickEntry")!) {
                        ZStack {
                            Circle()
                                .fill(WidgetTheme.accent)
                                .frame(width: 34, height: 34)
                                .shadow(color: WidgetTheme.accent.opacity(0.35), radius: 8, x: 0, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(WidgetTheme.accentForeground)
                        }
                    }
                }
            }
            .padding(16)
        }
        .widgetURL(URL(string: "justone://quickEntry"))
        .joWidgetBackground()
    }

    private func formatCurrency(cents: Int, symbol: String) -> String {
        let value = Decimal(cents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        let number = formatter.string(from: value as NSDecimalNumber) ?? "0"
        return "\(symbol)\(number)"
    }
}
