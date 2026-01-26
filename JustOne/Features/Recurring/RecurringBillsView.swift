import SwiftUI

struct RecurringBillsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: RecurringBillsViewModel
    @State private var showsForm = false
    private let recurringRepository: RecurringRepository
    private let categoryRepository: CategoryRepository
    private let billRepository: BillRepository

    init(recurringRepository: RecurringRepository, categoryRepository: CategoryRepository, billRepository: BillRepository) {
        self.recurringRepository = recurringRepository
        self.categoryRepository = categoryRepository
        self.billRepository = billRepository
        _viewModel = StateObject(wrappedValue: RecurringBillsViewModel(
            recurringRepository: recurringRepository,
            categoryRepository: categoryRepository
        ))
    }

    var body: some View {
        ZStack {
            JOColors.background.ignoresSafeArea()

            VStack(spacing: JOSpacing.lg) {
                header

                if viewModel.items.isEmpty {
                    Spacer(minLength: 0)
                    JOEmptyStateView(
                        title: "暂无定时记账",
                        subtitle: "点击右上角 + 新建"
                    )
                    Spacer(minLength: 0)
                } else {
                    ScrollView {
                        VStack(spacing: JOSpacing.md) {
                            ForEach(viewModel.items) { item in
                                RecurringBillRow(item: item)
                            }
                        }
                        .padding(.bottom, JOSpacing.xl)
                    }
                }
            }
            .padding(.horizontal, JOSpacing.lg)
            .padding(.top, JOSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
            viewModel.load()
        }
        .sheet(isPresented: $showsForm) {
            RecurringBillFormSheet(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                billRepository: billRepository
            ) {
                showsForm = false
                viewModel.load()
            }
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack {
            JOBackButton {
                dismiss()
            }

            Spacer()

            Text("定时记账")
                .font(JOTypography.headline)
                .foregroundStyle(JOColors.profileRowTitle)

            Spacer()

            JOIconButton(systemName: "plus") {
                showsForm = true
            }
        }
    }
}

private struct RecurringBillRow: View {
    let item: RecurringBillsViewModel.Item

    var body: some View {
        JOCard {
            HStack(spacing: JOSpacing.md) {
                JOCategoryIconTile(
                    iconName: item.icon,
                    title: item.title,
                    iconColor: item.iconColor,
                    size: 44,
                    iconSize: 18,
                    showsTitle: false,
                    backgroundColor: JOColors.categoryItemBackground
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(JOTypography.body)
                        .foregroundStyle(JOColors.textPrimary)

                    Text("\(item.repeatText) · \(item.nextFireText)")
                        .font(JOTypography.caption)
                        .foregroundStyle(JOColors.textSecondary)
                }

                Spacer()

                JOAmountText(
                    cents: item.amountCents,
                    size: .row,
                    color: item.isIncome ? JOColors.accent : JOColors.textPrimary
                )
            }
        }
    }
}
