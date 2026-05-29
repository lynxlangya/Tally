import Foundation

extension BillsListViewModel {
    enum TimeRange: String, CaseIterable, Identifiable {
        case week
        case month
        case year
        case custom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .week: return TallyLocalization.text(.timeRangeWeek, locale: LanguageManager.shared.currentLocale)
            case .month: return TallyLocalization.text(.timeRangeMonth, locale: LanguageManager.shared.currentLocale)
            case .year: return TallyLocalization.text(.timeRangeYear, locale: LanguageManager.shared.currentLocale)
            case .custom: return TallyLocalization.text(.timeRangeCustom, locale: LanguageManager.shared.currentLocale)
            }
        }

        var summaryPrefix: String {
            TallyLocalization.text(.summaryTotal, locale: LanguageManager.shared.currentLocale)
        }
    }

    enum RankSort: String, CaseIterable, Identifiable {
        case most
        case least

        var id: String { rawValue }

        var title: String {
            switch self {
            case .most: return TallyLocalization.text("most", locale: LanguageManager.shared.currentLocale)
            case .least: return TallyLocalization.text("least", locale: LanguageManager.shared.currentLocale)
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
        let iconName: String
        let iconColorHex: UInt32?
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
