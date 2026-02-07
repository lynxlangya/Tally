import Foundation

protocol RecurringService {
    func runCatchUp(maxDays: Int) throws -> Int
    func detectDuplicate(for draft: BillDraft) throws -> Bool
}

struct DefaultRecurringService: RecurringService {
    private let recurringRepository: RecurringRepository
    private let billRepository: BillRepository
    private let nowProvider: () -> Date
    private let calendar: Calendar

    init(
        recurringRepository: RecurringRepository,
        billRepository: BillRepository,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.recurringRepository = recurringRepository
        self.billRepository = billRepository
        self.nowProvider = nowProvider
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        self.calendar = calendar
    }

    func runCatchUp(maxDays: Int) throws -> Int {
        guard maxDays >= 0 else { return 0 }
        let now = nowProvider()
        let earliestAllowedDate = calendar.date(byAdding: .day, value: -maxDays, to: now) ?? now
        var createdCount = 0

        for task in try recurringRepository.list() where task.isEnabled {
            let (created, updated) = try process(task: task, now: now, earliestAllowedDate: earliestAllowedDate)
            createdCount += created
            if let updated {
                try recurringRepository.update(updated)
            }
        }

        return createdCount
    }

    func detectDuplicate(for draft: BillDraft) throws -> Bool {
        let snapshot = TimePolicy.snapshot(for: draft.occurredAtLocal)
        let dayBills = try billRepository.list(
            fromDayKey: snapshot.occurredLocalDate,
            toDayKey: snapshot.occurredLocalDate,
            type: draft.type
        )
        return dayBills.contains { record in
            record.isFromRecurring
            && record.occurredAtUTC == snapshot.occurredAtUTC
            && record.amount.cents == draft.amount.cents
            && record.categoryId == draft.categoryId
            && normalized(record.note) == normalized(draft.note)
        }
    }

    private func process(
        task: RecurringTaskRecord,
        now: Date,
        earliestAllowedDate: Date
    ) throws -> (created: Int, updated: RecurringTaskRecord?) {
        var currentTask = task
        var createdCount = 0
        var didAdvance = false
        let rule = RepeatRule(rawValue: task.repeatRule) ?? .daily

        while currentTask.nextFireDate <= now {
            if currentTask.nextFireDate >= earliestAllowedDate {
                let draft = BillDraft(
                    type: currentTask.type,
                    amount: currentTask.amount,
                    occurredAtLocal: currentTask.nextFireDate,
                    note: currentTask.note,
                    categoryId: currentTask.categoryId,
                    isFromRecurring: true
                )
                if try !detectDuplicate(for: draft) {
                    _ = try billRepository.create(draft)
                    createdCount += 1
                }
            }

            let nextNow = currentTask.nextFireDate.addingTimeInterval(1)
            var nextFireDate = RecurringScheduler.computeNextFireDate(
                firstDate: currentTask.nextFireDate,
                rule: rule,
                now: nextNow,
                calendar: calendar
            )
            if nextFireDate <= currentTask.nextFireDate {
                nextFireDate = calendar.date(byAdding: .day, value: 1, to: currentTask.nextFireDate) ?? nextNow
            }
            currentTask = RecurringTaskRecord(
                id: currentTask.id,
                type: currentTask.type,
                amount: currentTask.amount,
                categoryId: currentTask.categoryId,
                note: currentTask.note,
                firstDate: currentTask.firstDate,
                repeatRule: currentTask.repeatRule,
                nextFireDate: nextFireDate,
                hour: currentTask.hour,
                minute: currentTask.minute,
                lastRunAtUTC: now,
                isEnabled: currentTask.isEnabled,
                createdAt: currentTask.createdAt,
                updatedAt: now
            )
            didAdvance = true
        }

        if didAdvance {
            return (createdCount, currentTask)
        }
        return (createdCount, nil)
    }

    private func normalized(_ text: String?) -> String {
        (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct StubRecurringService: RecurringService {
    func runCatchUp(maxDays: Int) throws -> Int {
        0
    }

    func detectDuplicate(for draft: BillDraft) throws -> Bool {
        false
    }
}
