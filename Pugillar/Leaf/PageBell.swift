import Foundation
import UserNotifications

/// Role: Leaf. Daily local reminder to write today's page.
enum PageBell {
    static let identifier = "pgl.daily.page"

    @MainActor
    static func sync(on: Bool, hour: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard on else { return }
        let allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard allowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "Today's page is open"
        content.body = "Write your note, then pass the phone."
        content.sound = .default
        var parts = DateComponents()
        parts.hour = min(max(hour, 0), 23)
        parts.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        try? await center.add(
            UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        )
    }
}
