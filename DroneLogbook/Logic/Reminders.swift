import Foundation
import UserNotifications
import MJKit

/// Local-only expiry reminders (Pro). Notification text never contains IDs or numbers.
@MainActor
enum Reminders {
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Re-schedules everything: recurrent training (24 months) and every document with an expiry
    /// (registration defaults to 3 years; insurance and waivers use the date entered).
    static func reschedule(profile: PilotProfile, documents: [(label: String, expiry: Date)], leadDays: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        var items: [(String, Date)] = []
        if let due = profile.recurrentTrainingDue {
            items.append(("Part 107 recurrent training", due))
        }
        for doc in documents {
            items.append((doc.label, doc.expiry))
        }
        let now = Date()
        for (index, item) in items.enumerated() {
            let lead = Calendar.current.date(byAdding: .day, value: -leadDays, to: item.1) ?? item.1
            let fireDates: [(Date, String)] = [
                (lead, "\(item.0) expires in \(leadDays) days."),
                (item.1, "\(item.0) expires today.")
            ]
            for (n, fire) in fireDates.enumerated() where fire.0 > now {
                let content = UNMutableNotificationContent()
                content.title = "Drone Pocket Logbook"
                content.body = fire.1
                content.sound = .default
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: fire.0)
                comps.hour = 9
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: "dl.reminder.\(index).\(n)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
}
