import SwiftUI

struct BillsListCategoryDetailSheet: View {
    let detail: BillsListViewModel.CategoryDetail
    let onEdit: (UUID) -> Void

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(Color.tallyLineHi.opacity(0.72))
                .frame(width: BillsListLayout.detailSheetHandleWidth, height: BillsListLayout.detailSheetHandleHeight)
                .padding(.top, TallySpacing.s2)

            header
                .padding(.top, TallySpacing.s3)

            ScrollView {
                if detail.items.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(detail.items.enumerated()), id: \.element.id) { index, item in
                            Button {
                                onEdit(item.id)
                            } label: {
                                DetailRow(item: item, isIncome: detail.isIncome)
                            }
                            .buttonStyle(DetailRowButtonStyle())

                            if index < detail.items.count - 1 {
                                Divider()
                                    .background(Color.tallyLine)
                                    .padding(.leading, TallySpacing.s3)
                            }
                        }
                    }
                    .padding(.top, TallySpacing.s3)
                    .padding(.horizontal, TallySpacing.s4)
                    .padding(.bottom, TallySpacing.s4)
                    .background(Color.tallySurface)
                    .clipShape(RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous)
                            .stroke(Color.tallyLine, lineWidth: 0.5)
                    )
                }
            }
            .scrollIndicators(.hidden)
            .padding(.top, TallySpacing.s4)
        }
        .padding(.horizontal, BillsListLayout.horizontalPadding)
        .padding(.bottom, TallySpacing.s5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.tallyBg.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: TallySpacing.s4) {
            HStack(alignment: .center, spacing: TallySpacing.s3) {
                CategoryTile(
                    iconName: detail.iconName,
                    color: detailColor,
                    size: 40,
                    radius: TallyRadii.md
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(detail.title)
                        .font(TallyType.body(17, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)

                    Text("\(TallyLocalization.format(.entryCount, locale: LanguageManager.shared.currentLocale, detail.items.count)) · \(detail.isIncome ? TallyLocalization.text(.income, locale: LanguageManager.shared.currentLocale) : TallyLocalization.text(.expense, locale: LanguageManager.shared.currentLocale))")
                        .font(TallyType.body(11, weight: .medium))
                        .foregroundStyle(Color.tallyInkFaint)
                }

                Spacer(minLength: TallySpacing.s3)

                TallyAmountText(
                    cents: detail.totalCents,
                    sign: detail.isIncome ? .income : .expense,
                    size: 22,
                    weight: .semibold,
                    color: detail.isIncome ? themeColors.accent : .tallyInk
                )
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            }

            HStack(spacing: TallySpacing.s2) {
                MiniStatPill(
                    title: TallyLocalization.text(detail.isIncome ? .incomeDetail : .expenseDetail, locale: LanguageManager.shared.currentLocale),
                    value: TallyLocalization.format(.entryCount, locale: LanguageManager.shared.currentLocale, detail.items.count)
                )

                Spacer(minLength: 0)
            }
        }
        .padding(TallySpacing.s4)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.xl, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
        .tallyShadow(.shadow1)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        Text(TallyLocalization.text(.noDetails, locale: LanguageManager.shared.currentLocale))
            .font(TallyType.body(13, weight: .medium))
            .foregroundStyle(Color.tallyInkFaint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, TallySpacing.s6)
    }

    private var detailColor: Color {
        if let hex = detail.iconColorHex {
            return Color(hex: hex)
        }
        return .catAsh
    }
}

private struct DetailRow: View {
    let item: BillsListViewModel.CategoryDetailItem
    let isIncome: Bool

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        HStack(alignment: .center, spacing: TallySpacing.s3) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.noteText)
                    .font(TallyType.body(13, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                    .lineLimit(1)

                Text(item.dateText)
                    .font(TallyType.body(10, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: TallySpacing.s2) {
                TallyAmountText(
                    cents: item.amountCents,
                    sign: isIncome ? .income : .expense,
                    size: 14,
                    weight: .semibold,
                    color: isIncome ? themeColors.accent : .tallyInk
                )
                .lineLimit(1)
                .minimumScaleFactor(0.72)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.tallyInkGhost)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, BillsListLayout.detailRowVerticalPadding)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct MiniStatPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(TallyType.body(10, weight: .medium))
                .foregroundStyle(Color.tallyInkFaint)

            Text(value)
                .font(TallyType.num(11, weight: .semibold))
                .foregroundStyle(Color.tallyInkDim)
        }
        .padding(.horizontal, TallySpacing.s2)
        .frame(height: 24)
        .background(Color.tallySurface2)
        .clipShape(Capsule(style: .continuous))
    }
}

private struct DetailRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, TallySpacing.s1)
            .background(configuration.isPressed ? Color.tallySurface2 : Color.clear)
            .animation(.tallyFast, value: configuration.isPressed)
    }
}
