import Foundation

struct BillsListRankingBuilder {
    let sort: BillsListViewModel.RankSort
    let categoriesById: [UUID: CategoryRecord]

    func build(for bills: [BillRecord]) -> [BillsListViewModel.RankingItem] {
        let totalCents = bills.reduce(0) { $0 + $1.amount.cents }
        guard totalCents > 0 else { return [] }

        let totals = bills.reduce(into: [UUID: (amount: Int, count: Int)]()) { result, bill in
            let categoryId = bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
            let current = result[categoryId] ?? (0, 0)
            result[categoryId] = (current.amount + bill.amount.cents, current.count + 1)
        }

        let sorted = totals.filter { $0.value.amount > 0 }.sorted { lhs, rhs in
            if lhs.value.amount != rhs.value.amount {
                return sort == .most
                    ? lhs.value.amount > rhs.value.amount
                    : lhs.value.amount < rhs.value.amount
            }
            if lhs.value.count != rhs.value.count {
                return sort == .most
                    ? lhs.value.count > rhs.value.count
                    : lhs.value.count < rhs.value.count
            }
            let lhsName = categoriesById[lhs.key]?.name ?? ""
            let rhsName = categoriesById[rhs.key]?.name ?? ""
            if lhsName != rhsName {
                return lhsName.localizedStandardCompare(rhsName) == .orderedAscending
            }
            return lhs.key.uuidString < rhs.key.uuidString
        }

        return sorted.prefix(6).map { (id, value) in
            let category = categoriesById[id]
            let name = category?.name ?? "未分类"
            let iconName = category?.iconKey ?? "tag"
            let iconHex = category?.colorHex.map { UInt32($0) }
            let percent = Double(value.amount) / Double(totalCents)
            return BillsListViewModel.RankingItem(
                id: id,
                title: name,
                iconName: iconName,
                iconColorHex: iconHex,
                count: value.count,
                percent: percent,
                amountCents: value.amount
            )
        }
    }

    func categoryCount(for bills: [BillRecord]) -> Int {
        Set(bills.map { bill in
            bill.categoryId ?? SystemCategoryID.uncategorized(for: bill.type)
        }).count
    }
}
