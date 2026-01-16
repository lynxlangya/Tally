import Foundation

protocol RecurringService {
    func runCatchUp(maxDays: Int) throws -> Int
    func detectDuplicate(for draft: BillDraft) throws -> Bool
}

struct StubRecurringService: RecurringService {
    func runCatchUp(maxDays: Int) throws -> Int {
        0
    }

    func detectDuplicate(for draft: BillDraft) throws -> Bool {
        false
    }
}
