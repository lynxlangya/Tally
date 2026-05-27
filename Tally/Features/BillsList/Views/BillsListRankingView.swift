import SwiftUI

struct BillsListRankingView: View {
    let title: String
    let items: [BillsListViewModel.RankingItem]
    let onToggleSort: () -> Void
    let onSelectItem: (BillsListViewModel.RankingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LegacySpacing.md) {
            HStack {
                Text(title)
                    .font(LegacyTypography.headline)
                    .foregroundStyle(LegacyColors.textPrimary)

                Spacer()

                Button {
                    onToggleSort()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LegacyColors.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                if items.isEmpty {
                    LegacyEmptyStateView(
                        title: "没有排行。",
                        subtitle: "记一笔再看",
                        systemImage: "chart.bar"
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(spacing: BillsListLayout.rankingSpacing) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            Button {
                                onSelectItem(item)
                            } label: {
                                RankingRowView(item: item, isPrimary: index == 0)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity)
            .padding(.bottom, BillsListLayout.rankingBottomPadding)
        }
    }
}

private struct RankingRowView: View {
    let item: BillsListViewModel.RankingItem
    let isPrimary: Bool

    var body: some View {
        let percentText = String(format: "%.0f%%", item.percent * 100)
        let barColor = isPrimary ? LegacyColors.accent : LegacyColors.textSecondary.opacity(0.6)
        let dotColor = isPrimary ? LegacyColors.accent : LegacyColors.textSecondary.opacity(0.5)

        VStack(spacing: LegacySpacing.sm) {
            HStack {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)

                Text(item.title)
                    .font(LegacyTypography.body)
                    .foregroundStyle(LegacyColors.textPrimary)

                Text(percentText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isPrimary ? LegacyColors.accent : LegacyColors.textSecondary)

                Spacer()

                LegacyAmountText(cents: item.amountCents, size: .small)
            }

            GeometryReader { proxy in
                let width = max(proxy.size.width, 1)
                let barWidth = width * CGFloat(item.percent)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LegacyColors.surface)
                        .frame(height: BillsListLayout.rankBarHeight)
                        .overlay(
                            Capsule()
                                .stroke(LegacyColors.cardBorder, lineWidth: 1)
                        )

                    Capsule()
                        .fill(barColor)
                        .frame(width: barWidth, height: BillsListLayout.rankBarHeight)
                        .shadow(color: barColor.opacity(isPrimary ? 0.4 : 0.0), radius: 6, x: 0, y: 0)
                }
            }
            .frame(height: BillsListLayout.rankBarHeight)
        }
    }
}
