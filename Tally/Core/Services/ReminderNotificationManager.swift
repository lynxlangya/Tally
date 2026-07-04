import Foundation
import os
import UserNotifications

final class ReminderNotificationManager {
    static let shared = ReminderNotificationManager()
    private static let dailyReminderIdentifier = "dailyReminder"

    private let center: UNUserNotificationCenter
    private let logger = Logger(subsystem: "com.langya.Tally", category: "reminder")

    private init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            logger.error("Reminder authorization request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = TallyLocalization.text(.quickEntry, locale: LanguageManager.shared.currentLocale)
        content.body = TallyLocalization.text("daily_reminder_body", locale: LanguageManager.shared.currentLocale)
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: Self.dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
        } catch {
            logger.error("Daily reminder scheduling failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func rescheduleDailyReminderIfPending() async {
        let pending = await center.pendingNotificationRequests()
        guard let request = pending.first(where: { $0.identifier == Self.dailyReminderIdentifier }),
              let trigger = request.trigger as? UNCalendarNotificationTrigger,
              let hour = trigger.dateComponents.hour,
              let minute = trigger.dateComponents.minute
        else { return }

        await scheduleDailyReminder(hour: hour, minute: minute)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.dailyReminderIdentifier])
    }
}
