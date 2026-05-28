import SwiftUI

struct QuickEntryWidgetCard: View {
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
        .background(widgetCardBackground(cornerRadius: 24))
    }

    private var subtitle: String {
        let countText = "\(model.todayEntryCount) 笔"
        guard model.todayExpenseCents > 0,
              let yesterday = model.yesterdayExpenseCents,
              yesterday > 0 else {
            return countText
        }

        let delta = Double(model.todayExpenseCents - yesterday) / Double(yesterday)
        let percent = Int((abs(delta) * 100).rounded())
        let arrow = delta >= 0 ? "↑" : "↓"
        return "\(countText) · 较昨日 \(arrow) \(percent)%"
    }
}

struct SummaryTrendWidgetCard: View {
    let model: SummaryTrendWidgetModel

    var body: some View {
        HStack(spacing: 0) {
            leftPanel
                .frame(width: 126, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .leading)

            Rectangle()
                .fill(WidgetTheme.border)
                .frame(width: 0.5)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)

            rightPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetCardBackground(cornerRadius: 24))
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
                WidgetMiniCell(title: "收入", cents: model.monthIncomeCents)
                WidgetMiniCell(title: "结余", cents: model.monthBalanceCents)
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

private struct WidgetMiniCell: View {
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

private func widgetCardBackground(cornerRadius: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(WidgetTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(WidgetTheme.border, lineWidth: 0.5)
        )
}
