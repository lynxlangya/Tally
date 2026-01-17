import SwiftUI

struct BillsListView: View {
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: BillsListViewModel

    init(repository: BillRepository) {
        _viewModel = StateObject(wrappedValue: BillsListViewModel(repository: repository))
    }

    var body: some View {
        List {
            Section {
                Button("Add Sample Bill") {
                    viewModel.addSampleBill()
                }
            }

            if viewModel.dayKeys.isEmpty {
                Section {
                    Text("No bills")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(viewModel.dayKeys, id: \.self) { dayKey in
                    Section(dayKey) {
                        ForEach(viewModel.groupedBills[dayKey] ?? []) { bill in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(MoneyFormatter.string(from: bill.amount))
                                    .font(.headline)
                                Text(bill.note ?? "-")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Bills")
        .task {
            viewModel.load()
        }
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
    }
}

#Preview {
    let today = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
    let seed = BillRecord(
        id: UUID(),
        type: .expense,
        amount: Money(cents: 428560),
        occurredAtUTC: today,
        tzId: TimeZone.current.identifier,
        tzOffset: TimeZone.current.secondsFromGMT(),
        occurredLocalDate: DayKeyFormatter.dayKey(for: today),
        note: "Preview bill",
        categoryId: nil,
        isFromRecurring: false,
        createdAt: Date(),
        updatedAt: Date(),
        deletedAt: nil,
        trashUntil: nil
    )
    let seed2 = BillRecord(
        id: UUID(),
        type: .income,
        amount: Money(cents: 8800),
        occurredAtUTC: yesterday,
        tzId: TimeZone.current.identifier,
        tzOffset: TimeZone.current.secondsFromGMT(),
        occurredLocalDate: DayKeyFormatter.dayKey(for: yesterday),
        note: "Preview income",
        categoryId: nil,
        isFromRecurring: false,
        createdAt: Date(),
        updatedAt: Date(),
        deletedAt: nil,
        trashUntil: nil
    )
    let repository = MockBillRepository(seed: [seed, seed2])
    NavigationStack {
        BillsListView(repository: repository)
    }
}
