import SwiftUI

struct HomeView: View {
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: HomeViewModel
    @State private var editingBill: BillRecord?
    @State private var showsDeleteConfirm = false
    @State private var deleteCandidateId: UUID?

    private let repository: BillRepository
    private let categoryRepository: CategoryRepository

    init(repository: BillRepository, categoryRepository: CategoryRepository) {
        self.repository = repository
        self.categoryRepository = categoryRepository
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            repository: repository,
            categoryRepository: categoryRepository
        ))
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HomeHeader(
                        summary: viewModel.summary,
                        dailyAverageCents: viewModel.dailyAverageCents,
                        trend7Cents: viewModel.trend7Cents,
                        trend7Labels: viewModel.trend7Labels,
                        currentWeekdayText: viewModel.currentWeekdayText
                    )

                    if viewModel.groups.isEmpty {
                        HomeEmptyState()
                            .padding(.top, TallySpacing.s8)
                    } else {
                        VStack(spacing: TallySpacing.s5) {
                            ForEach(viewModel.groups) { group in
                                HomeDayGroupView(
                                    group: group,
                                    onSelect: { item in
                                        if let bill = viewModel.bill(for: item.id) {
                                            editingBill = bill
                                        }
                                    },
                                    onDelete: { item in
                                        deleteCandidateId = item.id
                                        showsDeleteConfirm = true
                                    }
                                )
                            }
                        }
                        .padding(.top, TallySpacing.s6)
                    }
                }
                .padding(.top, TallySpacing.s1)
                .padding(.bottom, HomeLayout.contentBottomPadding)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(true)
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .billDidChange)) { _ in
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .categoryDidChange)) { _ in
            viewModel.load()
        }
        .sheet(item: $editingBill) { bill in
            QuickEntryView(
                repository: repository,
                categoryRepository: categoryRepository,
                editingBill: bill
            )
        }
        .confirmationDialog("确定删除该账单？", isPresented: $showsDeleteConfirm, titleVisibility: .visible) {
            Button("确定删除", role: .destructive) {
                if let id = deleteCandidateId {
                    viewModel.deleteBill(id: id)
                }
                deleteCandidateId = nil
            }
            Button("取消", role: .cancel) {
                deleteCandidateId = nil
            }
        } message: {
            Text("该操作不可撤销")
        }
        .alert("操作未完成", isPresented: errorAlertBinding) {
            Button("知道了", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding {
            viewModel.errorMessage != nil
        } set: { isPresented in
            if !isPresented {
                viewModel.dismissError()
            }
        }
    }
}

private enum HomeLayout {
    static let horizontalPadding: CGFloat = 24
    static let contentBottomPadding: CGFloat = 120
}

private struct HomeHeader: View {
    let summary: HomeViewModel.Summary
    let dailyAverageCents: Int
    let trend7Cents: [Int]
    let trend7Labels: [String]
    let currentWeekdayText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TallyAmountText(
                cents: summary.expenseCents,
                size: 56,
                color: summary.expenseCents == 0 ? .tallyInkDim : .tallyInk,
                dim: summary.expenseCents == 0
            )
            .lineLimit(1)
            .minimumScaleFactor(0.72)

            Text("本月支出")
                .font(TallyType.body(12, weight: .medium))
                .tracking(12 * 0.04)
                .foregroundStyle(Color.tallyInkFaint)
                .padding(.top, TallySpacing.s1)

            HomeStatsRow(summary: summary, dailyAverageCents: dailyAverageCents)
                .padding(.top, 22)

            HomeTrendCard(
                trend7Cents: trend7Cents,
                trend7Labels: trend7Labels,
                currentWeekdayText: currentWeekdayText
            )
            .padding(.top, TallySpacing.s5)
        }
        .padding(.horizontal, HomeLayout.horizontalPadding)
        .padding(.top, TallySpacing.s4)
    }
}

private struct HomeStatsRow: View {
    let summary: HomeViewModel.Summary
    let dailyAverageCents: Int

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HomeStatCell(
                label: "收入",
                cents: summary.incomeCents,
                sign: .income,
                color: .tallyInk,
                alignment: .leading
            )

            HomeStatCell(
                label: "结余",
                cents: summary.balanceCents,
                sign: summary.balance >= 0 ? .income : .expense,
                color: summary.balance >= 0 ? themeColors.accent : .tallyInk,
                alignment: .center
            )

            HomeStatCell(
                label: "日均",
                cents: dailyAverageCents,
                sign: .none,
                color: .tallyInkDim,
                alignment: .trailing
            )
        }
        .padding(.top, TallySpacing.s5 - 2)
        .padding(.bottom, TallySpacing.s1)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.tallyLine)
                .frame(height: 0.5)
        }
    }
}

private struct HomeStatCell: View {
    enum Alignment {
        case leading
        case center
        case trailing

        var hAlignment: HorizontalAlignment {
            switch self {
            case .leading:
                return .leading
            case .center:
                return .center
            case .trailing:
                return .trailing
            }
        }

        var frameAlignment: SwiftUI.Alignment {
            switch self {
            case .leading:
                return .leading
            case .center:
                return .center
            case .trailing:
                return .trailing
            }
        }
    }

    let label: String
    let cents: Int
    let sign: TallyAmountText.Sign
    let color: Color
    let alignment: Alignment

    var body: some View {
        VStack(alignment: alignment.hAlignment, spacing: TallySpacing.s1) {
            Eyebrow(label)
            TallyAmountText(cents: cents, sign: sign, size: 17, weight: .semibold, color: color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
    }
}

private struct HomeTrendCard: View {
    let trend7Cents: [Int]
    let trend7Labels: [String]
    let currentWeekdayText: String

    @Environment(\.tallyThemeColors) private var themeColors

    private var currentAmount: Int {
        trend7Cents.last ?? 0
    }

    var body: some View {
        VStack(spacing: TallySpacing.s3) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("近 7 日")

                Spacer()

                Text(trendCaption)
                    .font(TallyType.body(11, weight: .medium))
                    .foregroundStyle(Color.tallyInkFaint)
                    .lineLimit(1)
            }

            GeometryReader { proxy in
                Sparkline(
                    data: trend7Cents.map(Double.init),
                    color: themeColors.accent,
                    fill: false,
                    dot: true,
                    baseline: true,
                    width: proxy.size.width,
                    height: 48
                )
            }
            .frame(height: 48)

            HStack {
                ForEach(Array(trend7Labels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(TallyType.body(10, weight: .medium))
                        .tracking(10 * 0.02)
                        .foregroundStyle(Color.tallyInkFaint)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, TallySpacing.s4)
        .padding(.vertical, TallySpacing.s4 - 2)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }

    private var trendCaption: String {
        "\(currentWeekdayText) \(compactAmountText(currentAmount))"
    }

    private func compactAmountText(_ cents: Int) -> String {
        let yuan = cents / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        let amount = formatter.string(from: NSNumber(value: yuan)) ?? "\(yuan)"
        return "¥\(amount)"
    }
}

private struct HomeDayGroupView: View {
    let group: HomeViewModel.Group
    let onSelect: (HomeViewModel.Item) -> Void
    let onDelete: (HomeViewModel.Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TallySpacing.s2) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.title)
                    .font(TallyType.body(12, weight: .medium))
                    .tracking(12 * 0.04)
                    .foregroundStyle(Color.tallyInkDim)

                Spacer()

                HomeDayGroupTotals(group: group)
            }
            .padding(.horizontal, HomeLayout.horizontalPadding)

            VStack(spacing: 0) {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                    HomeBillRow(
                        item: item,
                        onSelect: {
                            onSelect(item)
                        },
                        onDelete: {
                            onDelete(item)
                        }
                    )

                    if index < group.items.count - 1 {
                        Rectangle()
                            .fill(Color.tallyLine)
                            .frame(height: 0.5)
                            .padding(.leading, 64)
                            .padding(.trailing, TallySpacing.s4)
                    }
                }
            }
            .padding(.horizontal, TallySpacing.s2)
        }
    }
}

private struct HomeDayGroupTotals: View {
    let group: HomeViewModel.Group

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        HStack(spacing: TallySpacing.s2) {
            if group.expenseTotalCents > 0 {
                Text("−\(moneyText(group.expenseTotalCents))")
                    .foregroundStyle(Color.tallyInkFaint)
            }
            if group.incomeTotalCents > 0 {
                Text("+\(moneyText(group.incomeTotalCents))")
                    .foregroundStyle(themeColors.accent)
            }
        }
        .font(TallyType.num(12, weight: .medium))
        .lineLimit(1)
        .minimumScaleFactor(0.78)
    }

    private func moneyText(_ cents: Int) -> String {
        let parts = TallyAmountText.amountParts(cents: cents)
        return "¥\(parts.integer).\(parts.decimal)"
    }
}

private struct HomeBillRow: View {
    let item: HomeViewModel.Item
    let onSelect: () -> Void
    let onDelete: () -> Void

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: TallySpacing.s3) {
                CategoryTile(iconName: item.icon, color: item.iconColor, size: 36, radius: TallyRadii.md)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(TallyType.body(15, weight: .medium))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .font(TallyType.body(12, weight: .regular))
                            .foregroundStyle(Color.tallyInkFaint)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TallyAmountText(
                    cents: item.amountCents,
                    sign: item.isIncome ? .income : .expense,
                    size: 16,
                    weight: .semibold,
                    color: item.isIncome ? themeColors.accent : .tallyInk
                )
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            }
            .padding(.horizontal, TallySpacing.s4)
            .padding(.vertical, TallySpacing.s3)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HomeBillRowButtonStyle())
        .accessibilityLabel(Text("\(item.title) \(item.isIncome ? "收入" : "支出")"))
        .accessibilityAction(named: Text("删除"), onDelete)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

private struct HomeBillRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.tallySurface : Color.clear)
            .animation(.tallyFast, value: configuration.isPressed)
    }
}

private struct HomeEmptyState: View {
    var body: some View {
        VStack(spacing: TallySpacing.s3) {
            Image(systemName: "tray")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color.tallyInkFaint)
            Text("一根刻痕，一笔账。")
                .font(TallyType.display(17, weight: .semibold))
                .foregroundStyle(Color.tallyInk)
            Text("记一笔")
                .font(TallyType.body(13, weight: .regular))
                .foregroundStyle(Color.tallyInkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, HomeLayout.horizontalPadding)
    }
}

private extension HomeViewModel.Group {
    var expenseTotalCents: Int {
        items
            .filter { !$0.isIncome }
            .reduce(0) { $0 + $1.amountCents }
    }

    var incomeTotalCents: Int {
        items
            .filter(\.isIncome)
            .reduce(0) { $0 + $1.amountCents }
    }
}

#Preview("Home Light") {
    NavigationStack {
        HomeView(
            repository: AppEnvironment.preview.container.repositories.bill,
            categoryRepository: AppEnvironment.preview.container.repositories.category
        )
    }
    .environment(\.appEnvironment, .preview)
    .preferredColorScheme(.light)
}

#Preview("Home Dark") {
    NavigationStack {
        HomeView(
            repository: AppEnvironment.preview.container.repositories.bill,
            categoryRepository: AppEnvironment.preview.container.repositories.category
        )
    }
    .environment(\.appEnvironment, .preview)
    .preferredColorScheme(.dark)
}
