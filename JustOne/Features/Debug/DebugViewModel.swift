#if DEBUG
import Foundation
import Combine

@MainActor
final class DebugViewModel: ObservableObject {
    @Published private(set) var dayKey: String
    @Published private(set) var groupedBills: [String: [BillRecord]] = [:]
    @Published private(set) var statusMessage: String?

    private let billRepository: BillRepository
    private let seedService: SeedService

    init(billRepository: BillRepository, seedService: SeedService) {
        self.billRepository = billRepository
        self.seedService = seedService
        self.dayKey = DayKeyFormatter.dayKey(for: Date())
    }

    func seedIfNeeded() {
        do {
            try seedService.seedIfNeeded()
            statusMessage = "Seeded categories"
        } catch {
            statusMessage = "Seed failed: \(error)"
        }
    }

    func createRandomBill() {
        let amount = Int.random(in: 100...5000)
        let draft = BillDraft(
            type: .expense,
            amount: Money(cents: amount),
            occurredAtLocal: Date(),
            note: "Debug \(amount)",
            categoryId: nil,
            isFromRecurring: false
        )

        do {
            _ = try billRepository.create(draft)
            statusMessage = "Created bill"
        } catch {
            statusMessage = "Create failed: \(error)"
        }
    }

    func refresh() {
        let key = DayKeyFormatter.dayKey(for: Date())
        dayKey = key
        do {
            let bills = try billRepository.fetch(by: key)
            groupedBills = [key: bills]
            statusMessage = nil
        } catch {
            statusMessage = "Fetch failed: \(error)"
        }
    }
}
#endif
