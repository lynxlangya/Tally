import Foundation

enum DayKeyFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func dayKey(for date: Date, timeZone: TimeZone = .current) -> String {
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    static func date(from dayKey: String, timeZone: TimeZone = .current) -> Date? {
        formatter.timeZone = timeZone
        return formatter.date(from: dayKey)
    }
}
