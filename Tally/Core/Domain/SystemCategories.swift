import Foundation

enum SystemCategoryID {
    static let uncategorizedExpense = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let uncategorizedIncome = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    static func uncategorized(for type: BillType) -> UUID {
        switch type {
        case .expense:
            return uncategorizedExpense
        case .income:
            return uncategorizedIncome
        }
    }
}
