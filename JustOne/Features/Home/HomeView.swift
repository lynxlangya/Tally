import SwiftUI

struct HomeView: View {
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: HomeViewModel
    @State private var showsBillsList = false
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
            JOColors.background.ignoresSafeArea()

            VStack(spacing: JOSpacing.md) {
                header

                listContent
            }
            .padding(.top, JOSpacing.md)
        }
        .overlay(alignment: .bottom) {
            GeometryReader { proxy in
                let height = HomeLayout.bottomOverlayHeight + proxy.safeAreaInsets.bottom
                JOBottomGradientBlurOverlay(height: height, maxOpacity: HomeLayout.bottomOverlayOpacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
            .allowsHitTesting(false)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(true)
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .billDidChange)) { _ in
            viewModel.load()
        }
        .navigationDestination(isPresented: $showsBillsList) {
            BillsListView(
                repository: repository,
                categoryRepository: categoryRepository
            )
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
    }

    private var header: some View {
        HStack(alignment: .top, spacing: JOSpacing.lg) {
            summarySection

            Spacer()

            JOIconButton(systemName: "calendar") {
                showsBillsList = true
            }
        }
        .padding(.horizontal, JOSpacing.lg)
        .padding(.top, JOSpacing.md)
        .padding(.bottom, JOSpacing.sm)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: JOSpacing.md) {
            Text("本月支出")
                .font(JOTypography.caption)
                .foregroundStyle(JOColors.textSecondary)
            JOAmountText(cents: viewModel.summary.expenseCents, size: .large)

            HStack(spacing: JOSpacing.xl) {
                VStack(alignment: .leading, spacing: JOSpacing.xs) {
                    Text("本月收入")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    JOAmountText(cents: viewModel.summary.incomeCents, size: .small, color: JOColors.accent)
                }
                VStack(alignment: .leading, spacing: JOSpacing.xs) {
                    Text("结余")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                    JOAmountText(
                        cents: viewModel.summary.balanceCents,
                        sign: viewModel.summary.balanceSign,
                        size: .small,
                        color: viewModel.summary.balanceSign == "+" ? JOColors.accent : JOColors.textPrimary
                    )
                }
            }
        }
    }

    private var listContent: some View {
        List {
            if viewModel.groups.isEmpty {
                Section {
                    JOEmptyStateView(
                        title: "暂无账单",
                        subtitle: "点击 + 记一笔",
                        systemImage: "tray"
                    )
                    .padding(.top, JOSpacing.lg + 50)
                    .listRowInsets(
                        EdgeInsets(
                            top: 0,
                            leading: JOSpacing.lg,
                            bottom: JOSpacing.lg,
                            trailing: JOSpacing.lg
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(viewModel.groups) { group in
                    Section {
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                            Button {
                                if let bill = viewModel.bill(for: item.id) {
                                    editingBill = bill
                                }
                            } label: {
                                HomeListRowContent(
                                    iconName: item.icon,
                                    iconColor: item.iconColor,
                                    title: item.title,
                                    subtitle: item.subtitle,
                                    amountCents: item.amountCents,
                                    amountSign: item.isIncome ? "+" : "-",
                                    amountColor: item.isIncome ? JOColors.accent : JOColors.textPrimary
                                )
                                .background(
                                    HomeGroupRowBackground(
                                        isFirst: index == 0,
                                        isLast: index == group.items.count - 1
                                    )
                                )
                                .overlay(alignment: .bottom) {
                                    if index < group.items.count - 1 {
                                        Rectangle()
                                            .fill(JOColors.cardBorder.opacity(0.35))
                                            .frame(height: 1)
                                            .padding(.horizontal, JOSpacing.lg)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    deleteCandidateId = item.id
                                    showsDeleteConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .tint(.red)
                            }
                            .listRowInsets(
                                EdgeInsets(
                                    top: 0,
                                    leading: JOSpacing.lg,
                                    bottom: 0,
                                    trailing: JOSpacing.lg
                                )
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        groupHeader(group)
                    }
                    .textCase(nil)
                    .listSectionSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 140)
        }
    }

    private func groupHeader(_ group: HomeViewModel.Group) -> some View {
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
        .padding(.horizontal, JOSpacing.lg)
        .padding(.vertical, JOSpacing.sm)
    }
}

private enum HomeLayout {
    static let bottomOverlayHeight: CGFloat = 90
    static let bottomOverlayOpacity: Double = 0.72
}

private struct HomeListRowContent: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let amountCents: Int
    let amountSign: String?
    let amountColor: Color

    var body: some View {
        HStack(spacing: JOSpacing.md) {
            JOIcon(
                name: iconName,
                size: 15,
                weight: .semibold,
                color: iconColor
            )
            .frame(width: 46, height: 46)
            .background(JOColors.categoryItemBackground)
            .clipShape(Circle())
            .shadow(color: iconColor.opacity(0.1), radius: 6, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(JOTypography.body)
                    .foregroundStyle(JOColors.textPrimary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                }
            }
            Spacer()
            JOAmountText(cents: amountCents, sign: amountSign, size: .row, color: amountColor)
        }
        .padding(.vertical, JOSpacing.sm)
        .padding(.horizontal, JOSpacing.lg)
        .frame(minHeight: 72)
    }
}

private struct HomeGroupRowBackground: View {
    let isFirst: Bool
    let isLast: Bool

    private var corners: UIRectCorner {
        if isFirst && isLast {
            return [.topLeft, .topRight, .bottomLeft, .bottomRight]
        }
        if isFirst {
            return [.topLeft, .topRight]
        }
        if isLast {
            return [.bottomLeft, .bottomRight]
        }
        return []
    }

    var body: some View {
        JOColors.surface
            .clipShape(RoundedCorner(radius: JORadius.row, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        HomeView(
            repository: AppEnvironment.preview.container.repositories.bill,
            categoryRepository: AppEnvironment.preview.container.repositories.category
        )
    }
    .environment(\.appEnvironment, .preview)
}
