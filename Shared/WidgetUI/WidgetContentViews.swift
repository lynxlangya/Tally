import SwiftUI

struct QuickEntryWidgetCard: View {
    let model: QuickEntryWidgetModel
    private let locale = TallyLocalization.widgetLocale

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

                Text(TallyLocalization.text(.today, locale: locale))
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
                    color: WidgetTheme.textPrimary,
                    locale: locale
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
                Text(TallyLocalization.text(.quickEntry, locale: locale))
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
        let countText = TallyLocalization.format(.entryCount, locale: locale, model.todayEntryCount)
        guard model.todayExpenseCents > 0,
              let yesterday = model.yesterdayExpenseCents,
              yesterday > 0 else {
            return countText
        }

        let delta = Double(model.todayExpenseCents - yesterday) / Double(yesterday)
        let percent = Int((abs(delta) * 100).rounded())
        let arrow = delta >= 0 ? "↑" : "↓"
        return TallyLocalization.format("yesterday_change_format", locale: locale, countText, arrow, percent)
    }
}

struct SummaryTrendWidgetCard: View {
    let model: SummaryTrendWidgetModel
    private let locale = TallyLocalization.widgetLocale

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
                Text(monthText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textFaint)
            }

            Spacer(minLength: 9)

            VStack(alignment: .leading, spacing: 4) {
                Text(TallyLocalization.text(.expense, locale: locale))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textFaint)

                WidgetTheme.amountText(
                    cents: model.monthExpenseCents,
                    size: 22,
                    weight: .semibold,
                    color: WidgetTheme.textPrimary,
                    locale: locale
                )
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 10)

            HStack(spacing: 8) {
                WidgetMiniCell(title: TallyLocalization.text(.income, locale: locale), cents: model.monthIncomeCents, locale: locale)
                WidgetMiniCell(title: TallyLocalization.text(.balance, locale: locale), cents: model.monthBalanceCents, locale: locale)
            }
        }
    }

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(TallyLocalization.text(.recent7Days, locale: locale))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textFaint)

                Spacer(minLength: 6)

                Text(WidgetTheme.compactMoney(cents: model.average7Cents, locale: locale))
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
                Text(weekdayStartText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WidgetTheme.textFaint)
                Spacer(minLength: 0)
                Text(TallyLocalization.text(.todayShort, locale: locale))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
    }

    private var monthText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: Date())
        components.month = model.monthNumber
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    private var weekdayStartText: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        let symbols = formatter.shortWeekdaySymbols ?? []
        return symbols.isEmpty ? "Mon" : symbols[1]
    }
}

private struct WidgetMiniCell: View {
    let title: String
    let cents: Int
    let locale: Locale

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(WidgetTheme.textFaint)
                .lineLimit(1)
            Text(WidgetTheme.compactMoney(cents: cents, locale: locale))
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
