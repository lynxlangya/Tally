import Foundation
import Combine

@MainActor
final class BillsListViewModel: ObservableObject {
    @Published private(set) var groupedBills: [String: [BillRecord]] = [:]
    @Published private(set) var dayKeys: [String] = []
    @Published private(set) var errorMessage: String?

    private let repository: BillRepository

    init(repository: BillRepository) {
        self.repository = repository
    }

    func load() {
        do {
            let bills = try repository.list()
            let grouped = Dictionary(grouping: bills, by: { $0.occurredLocalDate })
            groupedBills = grouped.mapValues { items in
                items.sorted { $0.occurredAtUTC > $1.occurredAtUTC }
            }
            dayKeys = groupedBills.keys.sorted(by: >)
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func addSampleBill() {
        let draft = BillDraft(
            type: .expense,
            amount: Money(cents: 1288),
            occurredAtLocal: Date(),
            note: "Sample bill",
            categoryId: nil,
            isFromRecurring: false
        )

        do {
            _ = try repository.create(draft)
            load()
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
