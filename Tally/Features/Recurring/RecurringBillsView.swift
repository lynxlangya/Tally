import SwiftUI

struct RecurringBillsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: RecurringBillsViewModel
    @State private var showsForm = false
    @State private var editingTask: RecurringTaskRecord?
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
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TallyNavHeader(
                    title: "定时记账",
                    onBack: { dismiss() },
                    trailing: AnyView(addButton)
                )

                summaryRow

                if viewModel.items.isEmpty {
                    Spacer(minLength: 0)
                    LegacyEmptyStateView(
                        title: "还没有定时账单。"
                    )
                    Spacer(minLength: 0)
                } else {
                    List {
                        ForEach(viewModel.items) { item in
                            RecurringBillRow(item: item)
                                .contentShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
                                .onTapGesture { editingTask = item.task }
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.delete(id: item.id)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.toggleEnabled(id: item.id, isEnabled: !item.isEnabled)
                                    } label: {
                                        Label(item.isEnabled ? "暂停" : "启用", systemImage: item.isEnabled ? "pause.fill" : "play.fill")
                                    }
                                    .tint(item.isEnabled ? .orange : .green)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .safeAreaPadding(.bottom, 120)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility?.setVisible(false)
            viewModel.load()
        }
        .tallySheet(isPresented: $showsForm, heightFraction: 0.62) {
            RecurringBillFormSheet(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                billRepository: billRepository
            ) {
                showsForm = false
                viewModel.load()
            }
        }
        .tallySheet(item: $editingTask, heightFraction: 0.62) { task in
            RecurringBillFormSheet(
                recurringRepository: recurringRepository,
                categoryRepository: categoryRepository,
                billRepository: billRepository,
                existingTask: task
            ) {
                editingTask = nil
                viewModel.load()
            }
        }
    }

    private var addButton: some View {
        Button {
            showsForm = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.tallyAccentInk)
                .frame(width: 36, height: 36)
                .background(Color.tallyAccent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新建定时")
    }

    private var summaryRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Eyebrow("已启用 \(viewModel.enabledCount) 条 · 暂停 \(viewModel.pausedCount) 条")

            Spacer(minLength: TallySpacing.s3)

            HStack(spacing: 3) {
                Text("每月固定支出")
                    .foregroundStyle(Color.tallyInkFaint)
                Text(MoneyFormatter.string(fromCents: viewModel.monthlyFixedExpenseCents))
                    .foregroundStyle(Color.tallyInkDim)
            }
            .font(TallyType.num(11, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.76)
        }
        .padding(.horizontal, TallySpacing.s6)
        .padding(.top, TallySpacing.s2)
        .padding(.bottom, TallySpacing.s3)
    }
}

private struct RecurringBillRow: View {
    let item: RecurringBillsViewModel.Item

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            CategoryTile(
                iconName: item.icon,
                color: item.iconColor,
                size: 40,
                radius: TallyRadii.md
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: TallySpacing.s2) {
                    Text(item.title)
                        .font(TallyType.body(15, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)

                    Chip(item.ruleText, tone: .outline, size: .xs)
                }

                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 10, weight: .regular))
                    Text("下次 \(item.nextFireText)")
                        .font(TallyType.body(11, weight: .medium))
                }
                .foregroundStyle(Color.tallyInkFaint)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TallyAmountText(
                cents: item.amountCents,
                sign: item.isIncome ? .income : .expense,
                size: 16,
                weight: .semibold,
                color: item.isIncome ? .tallyAccent : .tallyInk
            )
            .lineLimit(1)
            .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, TallySpacing.s4)
        .padding(.vertical, 14)
        .background(Color.tallySurface)
        .clipShape(RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TallyRadii.lg, style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
        .opacity(item.isEnabled ? 1 : 0.55)
    }
}
