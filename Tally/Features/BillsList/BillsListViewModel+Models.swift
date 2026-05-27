import Foundation

extension BillsListViewModel {
    enum TimeRange: String, CaseIterable, Identifiable {
        case week
        case month
        case quarter
        case year
        case custom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .week: return "周"
            case .month: return "月"
            case .quarter: return "季"
            case .year: return "年"
            case .custom: return "自定"
            }
        }

        var summaryPrefix: String {
            switch self {
            case .week: return "本周"
            case .month: return "本月"
            case .quarter: return "本季"
            case .year: return "本年"
            case .custom: return "自定"
            }
        }
    }

    enum RankSort: String, CaseIterable, Identifiable {
        case most
        case least

        var id: String { rawValue }

        var title: String {
            switch self {
            case .most: return "最多"
            case .least: return "最少"
            }
        }
    }

    struct SummaryChange {
        let percentText: String
        let isPositive: Bool
    }

    struct RankingItem: Identifiable {
        let id: UUID
        let title: String
        let iconName: String
        let iconColorHex: UInt32?
        let count: Int
        let percent: Double
        let amountCents: Int
    }

    struct Summary {
        let expenseCents: Int
        let incomeCents: Int

        var balanceCents: Int {
            incomeCents - expenseCents
        }
    }

    struct TrendPeak {
        let index: Int
        let label: String
        let amountCents: Int
    }

    struct RowItem: Identifiable {
        let id: UUID
        let title: String
        let subtitle: String
        let iconName: String
        let iconColorHex: UInt32?
        let amountCents: Int
        let isIncome: Bool
    }

    struct CategoryDetail {
        let id: UUID
        let title: String
        let totalCents: Int
        let isIncome: Bool
        let items: [CategoryDetailItem]
    }

    struct CategoryDetailItem: Identifiable {
        let id: UUID
        let dateText: String
        let noteText: String
        let amountCents: Int
    }
}
