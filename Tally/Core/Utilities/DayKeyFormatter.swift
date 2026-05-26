import Foundation

enum DayKeyFormatter {
    private static let threadDictionaryKey = "tally.daykey.formatter.storage"

    static func dayKey(for date: Date, timeZone: TimeZone = .current) -> String {
        formatter(for: timeZone).string(from: date)
    }

    static func date(from dayKey: String, timeZone: TimeZone = .current) -> Date? {
        formatter(for: timeZone).date(from: dayKey)
    }

    private static func formatter(for timeZone: TimeZone) -> DateFormatter {
        let threadDictionary = Thread.current.threadDictionary
        let storage: NSMutableDictionary
        if let existing = threadDictionary[threadDictionaryKey] as? NSMutableDictionary {
            storage = existing
        } else {
            let created = NSMutableDictionary()
            threadDictionary[threadDictionaryKey] = created
            storage = created
        }

        if let formatter = storage[timeZone.identifier] as? DateFormatter {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone
        storage[timeZone.identifier] = formatter
        return formatter
    }
}
