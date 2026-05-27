import SwiftUI
import WidgetKit

struct QuickEntryWidgetView: View {
    let model: QuickEntryWidgetModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                WidgetTallyMark(
                    variant: .one,
                    size: 16,
                    color: WidgetTheme.accent,
                    strokeWidth: 2.2
                )

                Spacer(minLength: 0)

                Text("今日")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textFaint)
                    .textCase(.uppercase)
            }

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 5) {
                WidgetTheme.amountText(
                    cents: model.todayExpenseCents,
                    size: 26,
                    weight: .semibold,
                    color: WidgetTheme.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.74)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetTheme.textFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer(minLength: 10)

            HStack(spacing: 6) {
                WidgetTallyMark(
                    variant: .one,
                    size: 12,
                    color: WidgetTheme.accentForeground,
                    strokeWidth: 1.7
                )
                Text("记一笔")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetTheme.accentForeground)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(WidgetTheme.accent)
            .clipShape(Capsule(style: .continuous))
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(WidgetTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(WidgetTheme.border, lineWidth: 0.5)
                )
        )
        .widgetURL(URL(string: "tally://quickEntry"))
        .joWidgetBackground()
    }

    private var subtitle: String {
        let countText = "\(model.todayEntryCount) 笔"
        guard let yesterday = model.yesterdayExpenseCents, yesterday > 0 else {
            return countText
        }

        let delta = Double(model.todayExpenseCents - yesterday) / Double(yesterday)
        let percent = Int((abs(delta) * 100).rounded())
        let arrow = delta >= 0 ? "↑" : "↓"
        return "\(countText) · 较昨日 \(arrow) \(percent)%"
    }
}
