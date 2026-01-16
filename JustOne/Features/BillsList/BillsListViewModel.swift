import Foundation
import Combine

@MainActor
final class BillsListViewModel: ObservableObject {
    @Published private(set) var bills: [BillRecord] = []
    @Published private(set) var errorMessage: String?
    @Published var dayKey: String

    private let repository: BillRepository

    init(repository: BillRepository, dayKey: String? = nil) {
        self.repository = repository
        self.dayKey = dayKey ?? DayKeyFormatter.dayKey(for: Date())
    }

    func load() {
        do {
            bills = try repository.fetch(by: dayKey)
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
