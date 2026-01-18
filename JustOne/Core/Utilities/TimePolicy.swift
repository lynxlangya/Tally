import Foundation

struct TimeSnapshot: Equatable, Codable {
    let occurredAtUTC: Date
    let tzId: String
    let tzOffset: Int
    let occurredLocalDate: String
}

enum TimePolicy {
    static func snapshot(for localDate: Date, timeZone: TimeZone = .current) -> TimeSnapshot {
        let tzId = timeZone.identifier
        let tzOffset = timeZone.secondsFromGMT(for: localDate)
        let occurredLocalDate = DayKeyFormatter.dayKey(for: localDate, timeZone: timeZone)
        // Date is an absolute instant; storing it as occurredAtUTC keeps the true timestamp.
        let occurredAtUTC = localDate
        return TimeSnapshot(
            occurredAtUTC: occurredAtUTC,
            tzId: tzId,
            tzOffset: tzOffset,
            occurredLocalDate: occurredLocalDate
        )
    }

    static func displayComponents(from occurredAtUTC: Date, timeZone: TimeZone = .current) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents(in: timeZone, from: occurredAtUTC)
    }
}
