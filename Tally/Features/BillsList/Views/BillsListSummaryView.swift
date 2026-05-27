import SwiftUI

struct BillsListSummaryView: View {
    let title: String
    let totalCents: Int
    let change: BillsListViewModel.SummaryChange?
    let type: BillType

    var body: some View {
        VStack(alignment: .leading, spacing: LegacySpacing.sm) {
            Text(title)
                .font(LegacyTypography.caption)
                .foregroundStyle(LegacyColors.textSecondary)

            HStack(alignment: .bottom, spacing: LegacySpacing.md) {
                LegacyAmountText(cents: totalCents, size: .large)

                if let change {
                    TrendBadge(text: change.percentText, isPositive: change.isPositive, type: type)
                }
            }
        }
    }
}

private struct TrendBadge: View {
    let text: String
    let isPositive: Bool
    let type: BillType

    var body: some View {
        let isExpense = type == .expense
        let isIncrease = isPositive
        let shouldUseRed = isExpense ? isIncrease : !isIncrease
        let background = shouldUseRed ? Color.red.opacity(0.22) : LegacyColors.accent.opacity(0.22)
        let symbol = isPositive ? "arrow.up.right" : "arrow.down.right"

        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(background)
        .clipShape(Capsule())
    }
}
