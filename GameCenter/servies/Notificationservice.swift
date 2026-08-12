import UserNotifications
import Foundation

/// Wraps `UNUserNotificationCenter` for the daily challenge reminder.
/// Settings tab is the only thing that talks to this.
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    static let dailyChallengeIdentifier = "dailyChallengeReminder"

    @Published private(set) var isAuthorized = false

    private init() {
        Task { await refreshAuthorizationStatus() }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Requests permission; returns whether it was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    /// Schedules (or replaces) a daily repeating local notification at the
    /// given time.
    func scheduleDailyChallenge(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyChallengeIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Daily Challenge"
        content.body = "Your daily challenge is ready — jump back in and beat your best score!"
        content.sound = .default

        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.dailyChallengeIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelDailyChallenge() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.dailyChallengeIdentifier])
    }
}
