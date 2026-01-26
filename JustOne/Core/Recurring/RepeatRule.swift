import Foundation

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
    case daily
    case weeklyMonday
    case weeklySunday
    case monthlyFirst
    case monthlyLast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "每天"
        case .weeklyMonday:
            return "每周（周一）"
        case .weeklySunday:
            return "每周（周日）"
        case .monthlyFirst:
            return "每月（月初）"
        case .monthlyLast:
            return "每月（月末）"
        }
    }
}
