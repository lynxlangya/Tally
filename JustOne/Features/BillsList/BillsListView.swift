import SwiftUI

struct BillsListView: View {
    @StateObject private var viewModel: BillsListViewModel

    init(repository: BillRepository) {
        _viewModel = StateObject(wrappedValue: BillsListViewModel(repository: repository))
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("DayKey")
                    Spacer()
                    Text(viewModel.dayKey)
                        .foregroundStyle(.secondary)
                }
                Button("Add Sample Bill") {
                    viewModel.addSampleBill()
                }
            }

            Section("Bills") {
                ForEach(viewModel.bills) { bill in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(MoneyFormatter.string(from: bill.amount))
                            .font(.headline)
                        Text(bill.note ?? "-")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(bill.occurredLocalDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
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
    }
}

#Preview {
    let dayKey = DayKeyFormatter.dayKey(for: Date())
    let seed = BillRecord(
        id: UUID(),
        type: .expense,
        amount: Money(cents: 428560),
        occurredAtUTC: Date(),
        tzId: TimeZone.current.identifier,
        tzOffset: TimeZone.current.secondsFromGMT(),
        occurredLocalDate: dayKey,
        note: "Preview bill",
        categoryId: nil,
        isFromRecurring: false,
        createdAt: Date(),
        updatedAt: Date(),
        deletedAt: nil,
        trashUntil: nil
    )
    let repository = MockBillRepository(seed: [seed])
    NavigationStack {
        BillsListView(repository: repository)
    }
}
