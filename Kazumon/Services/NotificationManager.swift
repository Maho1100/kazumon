import UserNotifications

@Observable
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let message24hKeys: [(title: String, body: String)] = [
        ("notif_24h_1_title", "notif_24h_1_body"),
        ("notif_24h_2_title", "notif_24h_2_body"),
        ("notif_24h_3_title", "notif_24h_3_body"),
        ("notif_24h_4_title", "notif_24h_4_body"),
        ("notif_24h_5_title", "notif_24h_5_body"),
        ("notif_24h_6_title", "notif_24h_6_body"),
    ]

    private let message48hKeys: [(title: String, body: String)] = [
        ("notif_48h_1_title", "notif_48h_1_body"),
        ("notif_48h_2_title", "notif_48h_2_body"),
        ("notif_48h_3_title", "notif_48h_3_body"),
        ("notif_48h_4_title", "notif_48h_4_body"),
        ("notif_48h_5_title", "notif_48h_5_body"),
        ("notif_48h_6_title", "notif_48h_6_body"),
    ]

    private let message3dKeys: [(title: String, body: String)] = [
        ("notif_3d_1_title", "notif_3d_1_body"),
        ("notif_3d_2_title", "notif_3d_2_body"),
    ]

    private let message7dKeys: [(title: String, body: String)] = [
        ("notif_7d_1_title", "notif_7d_1_body"),
        ("notif_7d_2_title", "notif_7d_2_body"),
    ]

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error { print("通知許可エラー: \(error)") }
        }
    }

    func scheduleStreakReminders(playerName: String) {
        cancelAll()
        let fallback = NSLocalizedString("notif_fallback_name", comment: "")
        let name = playerName.isEmpty ? fallback : playerName

        let msg24 = message24hKeys.randomElement()!
        let msg48 = message48hKeys.randomElement()!

        let title24 = NSLocalizedString(msg24.title, comment: "").replacingOccurrences(of: "％NAME％", with: name)
        let body24 = NSLocalizedString(msg24.body, comment: "").replacingOccurrences(of: "％NAME％", with: name)
        let title48 = NSLocalizedString(msg48.title, comment: "").replacingOccurrences(of: "％NAME％", with: name)
        let body48 = NSLocalizedString(msg48.body, comment: "").replacingOccurrences(of: "％NAME％", with: name)

        schedule(id: "streak_24h", title: title24, body: body24, after: 60 * 60 * 24)
        schedule(id: "streak_48h", title: title48, body: body48, after: 60 * 60 * 24 * 2)

        let msg3d = message3dKeys.randomElement()!
        let title3d = NSLocalizedString(msg3d.title, comment: "").replacingOccurrences(of: "％NAME％", with: name)
        let body3d = NSLocalizedString(msg3d.body, comment: "").replacingOccurrences(of: "％NAME％", with: name)
        schedule(id: "streak_3d", title: title3d, body: body3d, after: 60 * 60 * 24 * 3)

        let msg7d = message7dKeys.randomElement()!
        let title7d = NSLocalizedString(msg7d.title, comment: "").replacingOccurrences(of: "％NAME％", with: name)
        let body7d = NSLocalizedString(msg7d.body, comment: "").replacingOccurrences(of: "％NAME％", with: name)
        schedule(id: "streak_7d", title: title7d, body: body7d, after: 60 * 60 * 24 * 7)
    }

    func cancelAll() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }

    private func schedule(id: String, title: String, body: String, after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("通知登録エラー(\(id)): \(error)") }
        }
    }
}
