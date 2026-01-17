import SwiftUI

struct DebugView: View {
    @Environment(\.tabBarVisibility) private var tabBarVisibility
    @StateObject private var viewModel: DebugViewModel

    init(repository: BillRepository, seedService: SeedService) {
        _viewModel = StateObject(wrappedValue: DebugViewModel(billRepository: repository, seedService: seedService))
    }

    var body: some View {
        List {
            Section("Actions") {
                Button("Seed Categories") {
                    viewModel.seedIfNeeded()
                }
                Button("Create Random Bill") {
                    viewModel.createRandomBill()
                    viewModel.refresh()
                }
                Button("Refresh") {
                    viewModel.refresh()
                }
            }

            Section("Grouped") {
                if let bills = viewModel.groupedBills[viewModel.dayKey] {
                    ForEach(bills) { bill in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(MoneyFormatter.string(from: bill.amount))
                                .font(.headline)
                            Text(bill.occurredLocalDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No bills")
                        .foregroundStyle(.secondary)
                }
            }

            if let statusMessage = viewModel.statusMessage {
                Section("Status") {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Debug")
        .task {
            viewModel.refresh()
        }
        .onAppear {
            tabBarVisibility?.setVisible(false)
        }
        .onDisappear {
            tabBarVisibility?.setVisible(true)
        }
    }
}

#Preview {
    DebugView(
        repository: MockBillRepository(),
        seedService: StubSeedService()
    )
    .environment(\.appEnvironment, .preview)
}
