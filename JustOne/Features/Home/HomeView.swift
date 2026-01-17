import SwiftUI

struct HomeView: View {
    @Environment(\.appEnvironment) private var environment
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @State private var showsBillsList = false

    var body: some View {
        ZStack {
            JOColors.background.ignoresSafeArea()

            VStack(spacing: JOSpacing.lg) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: JOSpacing.xl) {
                        summarySection
                        groupsSection
                    }
                    .padding(.bottom, 140)
                }
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.top, JOSpacing.xl)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(true)
        }
        .navigationDestination(isPresented: $showsBillsList) {
            BillsListView(repository: environment.container.repositories.bill)
        }
    }

    private var header: some View {
        HStack {
            Color.clear
                .frame(width: 40, height: 40)

            Spacer()

            Button {
            } label: {
                HStack(spacing: JOSpacing.xs) {
                    Text(summary.monthTitle)
                        .font(JOTypography.headline)
                        .foregroundStyle(JOColors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(JOColors.textSecondary)
                }
                .padding(.horizontal, JOSpacing.md)
                .padding(.vertical, JOSpacing.sm)
                .background(JOColors.surface.opacity(0.8))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            JOIconButton(systemName: "calendar") {
                showsBillsList = true
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.md) {
            Text("本月支出")
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)
            JOAmountText(cents: summary.expenseCents, size: .large)

            HStack(spacing: JOSpacing.xl) {
                VStack(alignment: .leading, spacing: JOSpacing.xs) {
                    Text("本月收入")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    JOAmountText(cents: summary.incomeCents, size: .small, color: JOColors.accent)
                }
                VStack(alignment: .leading, spacing: JOSpacing.xs) {
                    Text("结余")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    JOAmountText(
                        cents: summary.balanceCents,
                        sign: summary.balanceSign,
                        size: .small,
                        color: summary.balanceSign == "+" ? JOColors.accent : JOColors.textPrimary
                    )
                }
            }
        }
    }

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.lg) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: JOSpacing.md) {
                    HStack {
                        Text(group.title)
                            .font(JOTypography.caption)
                            .foregroundStyle(JOColors.textSecondary)
                        Spacer()
                        JOAmountText(
                            cents: group.totalCents,
                            sign: group.totalSign,
                            size: .small,
                            color: group.totalSign == "+" ? JOColors.accent : JOColors.textPrimary
                        )
                    }

                    VStack(spacing: JOSpacing.sm) {
                        ForEach(group.items) { item in
                            JOListRow(
                                iconName: item.icon,
                                iconBackground: item.iconBackground,
                                title: item.title,
                                subtitle: item.subtitle,
                                amountCents: item.amountCents,
                                amountSign: item.isIncome ? "+" : "-",
                                amountColor: item.isIncome ? JOColors.accent : JOColors.textPrimary
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct HomeSummary {
    let monthTitle: String
    let expenseCents: Int
    let incomeCents: Int

    var balance: Int {
        incomeCents - expenseCents
    }

    var balanceCents: Int {
        abs(balance)
    }

    var balanceSign: String {
        balance >= 0 ? "+" : "-"
    }
}

private struct HomeItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconBackground: Color
    let title: String
    let subtitle: String
    let amountCents: Int
    let isIncome: Bool
}

private struct HomeGroup: Identifiable {
    let id = UUID()
    let title: String
    let totalCents: Int
    let totalSign: String
    let items: [HomeItem]
}

private let summary = HomeSummary(
    monthTitle: "2023年10月",
    expenseCents: 428560,
    incomeCents: 850000
)

private let groups: [HomeGroup] = [
    HomeGroup(
        title: "今天",
        totalCents: 825,
        totalSign: "-",
        items: [
            HomeItem(
                icon: "cup.and.saucer.fill",
                iconBackground: JOColors.accent.opacity(0.2),
                title: "星巴克",
                subtitle: "09:41 · 咖啡",
                amountCents: 550,
                isIncome: false
            ),
            HomeItem(
                icon: "tram.fill",
                iconBackground: JOColors.categoryBlue.opacity(0.2),
                title: "交通",
                subtitle: "08:30 · 通勤",
                amountCents: 275,
                isIncome: false
            )
        ]
    ),
    HomeGroup(
        title: "昨天",
        totalCents: 191080,
        totalSign: "+",
        items: [
            HomeItem(
                icon: "cart.fill",
                iconBackground: JOColors.categoryOrange.opacity(0.2),
                title: "超市买菜",
                subtitle: "18:15 · 全食超市",
                amountCents: 8920,
                isIncome: false
            ),
            HomeItem(
                icon: "creditcard.fill",
                iconBackground: JOColors.accent.opacity(0.2),
                title: "工资",
                subtitle: "09:00 · 月薪",
                amountCents: 200000,
                isIncome: true
            )
        ]
    )
]

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(\.appEnvironment, .preview)
}
