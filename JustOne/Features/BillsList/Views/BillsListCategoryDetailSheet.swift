import SwiftUI

struct BillsListCategoryDetailSheet: View {
    let detail: BillsListViewModel.CategoryDetail

    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: BillsListLayout.detailSheetHandleWidth, height: BillsListLayout.detailSheetHandleHeight)
                .padding(.top, JOSpacing.sm)

            VStack(spacing: JOSpacing.sm) {
                Text(detail.title)
                    .font(JOTypography.headline)
                    .foregroundStyle(JOColors.textPrimary)

                JOAmountText(cents: detail.totalCents, size: .large)
            }

            ScrollView {
                if detail.items.isEmpty {
                    Text("暂无记录")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, JOSpacing.xl)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(detail.items.enumerated()), id: \.element.id) { index, item in
                            DetailRow(item: item, isIncome: detail.isIncome)

                            if index < detail.items.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(BillsListLayout.detailDividerOpacity))
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, JOSpacing.xl)
            .padding(.bottom, JOSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(JOColors.surface.opacity(0.7))
    }
}

private struct DetailRow: View {
    let item: BillsListViewModel.CategoryDetailItem
    let isIncome: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.dateText)
                    .font(JOTypography.body)
                    .foregroundStyle(JOColors.textPrimary)

                Text(item.noteText)
                    .font(JOTypography.caption)
                    .foregroundStyle(JOColors.textSecondary)
            }

            Spacer()

            JOAmountText(
                cents: item.amountCents,
                sign: isIncome ? "+" : "-",
                size: .small,
                color: isIncome ? JOColors.accent : JOColors.textPrimary
            )
        }
        .padding(.vertical, BillsListLayout.detailRowVerticalPadding)
    }
}
