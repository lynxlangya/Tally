import Foundation

enum BillTimeFormatter {
    private static let threadDictionaryKey = "tally.bill.time.formatter.storage"

    static func timeText(for bill: BillRecord) -> String {
        timeText(from: bill.occurredAtUTC, tzId: bill.tzId, tzOffset: bill.tzOffset)
    }

    static func timeText(from occurredAtUTC: Date, tzId: String, tzOffset: Int) -> String {
        let timeZone = TimePolicy.timeZone(tzId: tzId, tzOffset: tzOffset)
        return formatter(for: timeZone).string(from: occurredAtUTC)
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
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        storage[timeZone.identifier] = formatter
        return formatter
    }
}
