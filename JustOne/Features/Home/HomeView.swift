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

            VStack(spacing: JOSpacing.lg) {
                header

                listContent
            }
            .padding(.top, JOSpacing.xl)
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
        HStack {
            Color.clear
                .frame(width: 40, height: 40)

            Spacer()

            Button {
            } label: {
                HStack(spacing: JOSpacing.xs) {
                    Text(viewModel.summary.monthTitle)
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
        .padding(.horizontal, JOSpacing.lg)
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
            Section {
                summarySection
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

            ForEach(viewModel.groups) { group in
                Section {
                    ForEach(group.items) { item in
                        Button {
                            if let bill = viewModel.bill(for: item.id) {
                                editingBill = bill
                            }
                        } label: {
                            JOListRow(
                                iconName: item.icon,
                                iconColor: item.iconColor,
                                title: item.title,
                                subtitle: item.subtitle,
                                amountCents: item.amountCents,
                                amountSign: item.isIncome ? "+" : "-",
                                amountColor: item.isIncome ? JOColors.accent : JOColors.textPrimary
                            )
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
                                bottom: JOSpacing.sm,
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

#Preview {
    NavigationStack {
        HomeView(
            repository: AppEnvironment.preview.container.repositories.bill,
            categoryRepository: AppEnvironment.preview.container.repositories.category
        )
    }
    .environment(\.appEnvironment, .preview)
}
