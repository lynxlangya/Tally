import SwiftUI

struct BillsListCategoryDetailSheet: View {
    let detail: BillsListViewModel.CategoryDetail
    let onEdit: (UUID) -> Void

    var body: some View {
        LegacySheetContainer(
            cornerRadius: BillsListLayout.detailSheetCornerRadius,
            background: LegacyColors.surface.opacity(0.7)
        ) {
            VStack(spacing: LegacySpacing.lg) {
                LegacySheetHandle(
                    width: BillsListLayout.detailSheetHandleWidth,
                    height: BillsListLayout.detailSheetHandleHeight,
                    opacity: 0.3
                )
                .padding(.top, LegacySpacing.sm)

                VStack(spacing: LegacySpacing.sm) {
                    Text(detail.title)
                        .font(LegacyTypography.headline)
                        .foregroundStyle(LegacyColors.textPrimary)

                    LegacyAmountText(cents: detail.totalCents, size: .large)
                }

                ScrollView {
                    if detail.items.isEmpty {
                        Text("没有记录。")
                            .font(LegacyTypography.caption)
                            .foregroundStyle(LegacyColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, LegacySpacing.xl)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(detail.items.enumerated()), id: \.element.id) { index, item in
                                Button {
                                    onEdit(item.id)
                                } label: {
                                    DetailRow(item: item, isIncome: detail.isIncome)
                                }
                                .buttonStyle(.plain)

                                if index < detail.items.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(BillsListLayout.detailDividerOpacity))
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, LegacySpacing.xl)
                .padding(.bottom, LegacySpacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct DetailRow: View {
    let item: BillsListViewModel.CategoryDetailItem
    let isIncome: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.dateText)
                    .font(LegacyTypography.body)
                    .foregroundStyle(LegacyColors.textPrimary)

                Text(item.noteText)
                    .font(LegacyTypography.caption)
                    .foregroundStyle(LegacyColors.textSecondary)
            }

            Spacer()

            LegacyAmountText(
                cents: item.amountCents,
                sign: isIncome ? "+" : "-",
                size: .small,
                color: isIncome ? LegacyColors.accent : LegacyColors.textPrimary
            )
        }
        .padding(.vertical, BillsListLayout.detailRowVerticalPadding)
    }
}
