import Foundation

enum RecurringScheduler {
    static func computeNextFireDate(
        firstDate: Date,
        rule: RepeatRule,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        if firstDate >= now {
            return firstDate
        }

        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: firstDate)

        switch rule {
        case .daily:
            return calendar.nextDate(
                after: now,
                matching: timeComponents,
                matchingPolicy: .nextTime
            ) ?? firstDate

        case .weeklyMonday:
            return nextWeekly(weekday: 2, timeComponents: timeComponents, now: now, calendar: calendar)

        case .weeklySunday:
            return nextWeekly(weekday: 1, timeComponents: timeComponents, now: now, calendar: calendar)

        case .monthlyFirst:
            return nextMonthly(day: 1, timeComponents: timeComponents, now: now, calendar: calendar)

        case .monthlyLast:
            return nextMonthlyLast(timeComponents: timeComponents, now: now, calendar: calendar)
        }
    }

    private static func nextWeekly(
        weekday: Int,
        timeComponents: DateComponents,
        now: Date,
        calendar: Calendar
    ) -> Date {
        var components = timeComponents
        components.weekday = weekday
        return calendar.nextDate(
            after: now,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ) ?? now
    }

    private static func nextMonthly(
        day: Int,
        timeComponents: DateComponents,
        now: Date,
        calendar: Calendar
    ) -> Date {
        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        if let candidate = calendar.date(from: components), candidate >= now {
            return candidate
        }
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) {
            var nextComponents = calendar.dateComponents([.year, .month], from: nextMonth)
            nextComponents.day = day
            nextComponents.hour = timeComponents.hour
            nextComponents.minute = timeComponents.minute
            nextComponents.second = timeComponents.second
            return calendar.date(from: nextComponents) ?? now
        }
        return now
    }

    private static func nextMonthlyLast(
        timeComponents: DateComponents,
        now: Date,
        calendar: Calendar
    ) -> Date {
        if let candidate = lastDay(of: now, timeComponents: timeComponents, calendar: calendar),
           candidate >= now {
            return candidate
        }
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
           let candidate = lastDay(of: nextMonth, timeComponents: timeComponents, calendar: calendar) {
            return candidate
        }
        return now
    }

    private static func lastDay(
        of date: Date,
        timeComponents: DateComponents,
        calendar: Calendar
    ) -> Date? {
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return nil }
        let lastDay = range.upperBound - 1
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = lastDay
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        return calendar.date(from: components)
    }
}
