import Foundation

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
    case daily
    case weeklyMonday
    case weeklySunday
    case monthlyFirst
    case monthlyLast

    var id: String { rawValue }

    var title: String {
        let locale = LanguageManager.shared.currentLocale
        switch self {
        case .daily:
            return TallyLocalization.text("repeat_rule_daily_title", locale: locale)
        case .weeklyMonday:
            return TallyLocalization.text("repeat_rule_weekly_monday_title", locale: locale)
        case .weeklySunday:
            return TallyLocalization.text("repeat_rule_weekly_sunday_title", locale: locale)
        case .monthlyFirst:
            return TallyLocalization.text("repeat_rule_monthly_first_title", locale: locale)
        case .monthlyLast:
            return TallyLocalization.text("repeat_rule_monthly_last_title", locale: locale)
        }
    }
}
