import SwiftUI
import WidgetKit

struct SummaryTrendWidgetView: View {
    let model: SummaryTrendWidgetModel

    var body: some View {
        HStack(spacing: 0) {
            leftPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .layoutPriority(1.1)

            Rectangle()
                .fill(WidgetTheme.border)
                .frame(width: 0.5)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)

            rightPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(WidgetTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(WidgetTheme.border, lineWidth: 0.5)
                )
        )
        .widgetURL(URL(string: "tally://home"))
        .joWidgetBackground()
    }

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                WidgetTallyMark(variant: .five, size: 14, color: WidgetTheme.accent, strokeWidth: 1.8)
                Text("\(model.monthNumber) 月")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textFaint)
            }

            Spacer(minLength: 9)

            VStack(alignment: .leading, spacing: 4) {
                Text("支出")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textFaint)

                WidgetTheme.amountText(
                    cents: model.monthExpenseCents,
                    size: 22,
                    weight: .semibold,
                    color: WidgetTheme.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 10)

            HStack(spacing: 8) {
                MiniCell(title: "收入", cents: model.monthIncomeCents)
                MiniCell(title: "结余", cents: model.monthBalanceCents)
            }
        }
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("近 7 日")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textFaint)

                Spacer(minLength: 6)

                Text(WidgetTheme.compactMoney(cents: model.average7Cents))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 8)

            WidgetSparkline(
                data: model.trend7,
                height: 56,
                fill: true,
                dot: true,
                baseline: true
            )

            Spacer(minLength: 8)

            HStack {
                Text("周一")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WidgetTheme.textFaint)
                Spacer(minLength: 0)
                Text("今")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
    }
}

private struct MiniCell: View {
    let title: String
    let cents: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(WidgetTheme.textFaint)
                .lineLimit(1)
            Text(WidgetTheme.compactMoney(cents: cents))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
