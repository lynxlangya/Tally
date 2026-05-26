import Foundation
import UserNotifications

final class ReminderNotificationManager {
    static let shared = ReminderNotificationManager()

    private let center: UNUserNotificationCenter

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
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "记一笔"
        content.body = "别忘了记录今天的账单"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailyReminder",
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
        } catch {
            // ignore for MVP
        }
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        center.removeDeliveredNotifications(withIdentifiers: ["dailyReminder"])
    }
}
