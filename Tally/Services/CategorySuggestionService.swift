import Foundation

protocol CategorySuggestionService {
    /// 返回按建议度排序的全部候选分类 ID（不截断）。失败 / 无数据时回退稳定顺序。
    func orderedCategoryIDs(type: BillType, now: Date, candidates: [CategoryRecord]) -> [UUID]
}

struct DefaultCategorySuggestionService: CategorySuggestionService {
    private enum Constants {
        static let lookbackDays = 90
        static let minimumHistoryCount = 10
        static let timeWeight = 0.5
        static let recencyWeight = 0.3
        static let frequencyWeight = 0.2
        static let halfLifeDays = 10.0
        static let timeWindowHours = 1.5
        static let secondsPerDay = 86_400.0
        static let hoursPerDay = 24.0
    }

    private let billRepository: BillRepository

    init(billRepository: BillRepository) {
        self.billRepository = billRepository
    }

    func orderedCategoryIDs(type: BillType, now: Date, candidates: [CategoryRecord]) -> [UUID] {
        let range = Self.dayRange(endingAt: now)
        guard let records = try? billRepository.list(
            fromDayKey: range.fromDayKey,
            toDayKey: range.toDayKey,
            type: type
        ) else {
            return candidates.map(\.id)
        }

        return Self.orderedCategoryIDs(
            from: records,
            type: type,
            now: now,
            candidates: candidates
        )
    }

    static func orderedCategoryIDs(
        from records: [BillRecord],
        type: BillType,
        now: Date,
        candidates: [CategoryRecord]
    ) -> [UUID] {
        let fallback = sortedCandidates(candidates)
        guard !fallback.isEmpty else { return [] }

        let fallbackRank = Dictionary(uniqueKeysWithValues: fallback.enumerated().map { ($0.element.id, $0.offset) })
        let candidateIDs = Set(fallback.map(\.id))
        let uncategorizedID = SystemCategoryID.uncategorized(for: type)
        let range = dayRange(endingAt: now)

        let effectiveRecords = records.filter { record in
            guard record.type == type,
                  record.occurredLocalDate >= range.fromDayKey,
                  record.occurredLocalDate <= range.toDayKey,
                  !record.isFromRecurring,
                  let categoryID = record.categoryId,
                  categoryID != uncategorizedID,
                  candidateIDs.contains(categoryID) else {
                return false
            }
            return true
        }

        guard effectiveRecords.count >= Constants.minimumHistoryCount else {
            return fallback.map(\.id)
        }

        let currentHour = fractionalHour(from: now)
        var frequencyCounts: [UUID: Int] = [:]
        var timeCounts: [UUID: Int] = [:]
        var recencyValues: [UUID: Double] = [:]
        var totalTimeCount = 0
        var totalRecency = 0.0

        for record in effectiveRecords {
            guard let categoryID = record.categoryId else { continue }
            frequencyCounts[categoryID, default: 0] += 1

            let editorDate = TimePolicy.editorDate(
                from: record.occurredAtUTC,
                tzId: record.tzId,
                tzOffset: record.tzOffset
            )
            let recordHour = fractionalHour(from: editorDate)
            if circularHourDistance(from: currentHour, to: recordHour) <= Constants.timeWindowHours {
                timeCounts[categoryID, default: 0] += 1
                totalTimeCount += 1
            }

            let daysAgo = max(0, now.timeIntervalSince(record.occurredAtUTC) / Constants.secondsPerDay)
            let recency = exp(-daysAgo / Constants.halfLifeDays)
            recencyValues[categoryID, default: 0] += recency
            totalRecency += recency
        }

        let totalFrequency = Double(effectiveRecords.count)
        let scores = Dictionary(uniqueKeysWithValues: fallback.map { category in
            let frequency = Double(frequencyCounts[category.id, default: 0]) / totalFrequency
            let timeAffinity = totalTimeCount > 0
                ? Double(timeCounts[category.id, default: 0]) / Double(totalTimeCount)
                : 0
            let recency = totalRecency > 0
                ? recencyValues[category.id, default: 0] / totalRecency
                : 0
            let score = Constants.timeWeight * timeAffinity
                + Constants.recencyWeight * recency
                + Constants.frequencyWeight * frequency
            return (category.id, score)
        })

        return fallback.sorted { lhs, rhs in
            let lhsScore = scores[lhs.id, default: 0]
            let rhsScore = scores[rhs.id, default: 0]
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }
            return fallbackRank[lhs.id, default: .max] < fallbackRank[rhs.id, default: .max]
        }
        .map(\.id)
    }

    private static func sortedCandidates(_ candidates: [CategoryRecord]) -> [CategoryRecord] {
        candidates.sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
            }
            if lhs.name != rhs.name {
                return lhs.name < rhs.name
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private static func dayRange(endingAt now: Date) -> (fromDayKey: String, toDayKey: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let fromDate = calendar.date(byAdding: .day, value: -Constants.lookbackDays, to: now) ?? now
        return (
            DayKeyFormatter.dayKey(for: fromDate, timeZone: calendar.timeZone),
            DayKeyFormatter.dayKey(for: now, timeZone: calendar.timeZone)
        )
    }

    private static func fractionalHour(from date: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0) / 60
        let second = Double(components.second ?? 0) / 3_600
        return hour + minute + second
    }

    private static func circularHourDistance(from lhs: Double, to rhs: Double) -> Double {
        let direct = abs(lhs - rhs)
        return min(direct, Constants.hoursPerDay - direct)
    }
}

struct StubCategorySuggestionService: CategorySuggestionService {
    nonisolated init() {}

    func orderedCategoryIDs(type: BillType, now: Date, candidates: [CategoryRecord]) -> [UUID] {
        candidates.map(\.id)
    }
}
