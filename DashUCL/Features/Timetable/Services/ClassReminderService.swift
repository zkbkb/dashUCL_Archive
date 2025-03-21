import Foundation
import UserNotifications

/// Class reminder service for managing class reminder notifications
class ClassReminderService {
    static let shared = ClassReminderService()

    private init() {}

    // Default reminder time (minutes)
    private let defaultReminderTime: Int = 15

    // Notification category identifier
    private let classReminderCategory = "CLASS_REMINDER"

    // Notification sound
    private let defaultSound = UNNotificationSound.default

    /// Schedule reminder for class
    /// - Parameters:
    ///   - classInfo: Class information
    ///   - minutesBefore: Minutes before class to remind
    func scheduleReminder(for classInfo: ClassInfo, minutesBefore: Int? = nil) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Class Reminder"
        content.body =
            "\(classInfo.title) starts in \(minutesBefore ?? defaultReminderTime) minutes at \(classInfo.location)"
        content.sound = defaultSound
        content.badge = 1

        // Add user info for handling notification response
        content.userInfo = [
            "classId": classInfo.id,
            "title": classInfo.title,
            "location": classInfo.location,
        ]

        // Set notification category
        content.categoryIdentifier = classReminderCategory

        // Calculate trigger time
        let triggerDate = Calendar.current.date(
            byAdding: .minute,
            value: -(minutesBefore ?? defaultReminderTime),
            to: classInfo.startTime
        )

        // Ensure trigger time is in the future
        guard let triggerDate = triggerDate, triggerDate > Date() else {
            print("Cannot schedule reminder for past class")
            return
        }

        // Create date components
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        // Create notification request
        let identifier = "class-reminder-\(classInfo.id)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // Add notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule class reminder: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled class reminder: \(classInfo.title) at \(triggerDate)")
            }
        }
    }

    /// Cancel class reminder
    /// - Parameter classId: Class ID
    func cancelReminder(for classId: String) {
        let identifier = "class-reminder-\(classId)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            identifier
        ])
        print("Cancelled class reminder: \(classId)")
    }

    /// Cancel all reminders
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cancelled all class reminders")
    }

    /// Update class reminder
    /// - Parameters:
    ///   - classInfo: Class information
    ///   - minutesBefore: Minutes before class to remind
    func updateReminder(for classInfo: ClassInfo, minutesBefore: Int? = nil) {
        // First cancel existing reminder
        cancelReminder(for: classInfo.id)

        // Then schedule new reminder
        scheduleReminder(for: classInfo, minutesBefore: minutesBefore)
    }

    /// Get all pending reminders
    /// - Parameter completion: Completion callback, returns all pending reminder requests
    func getPendingReminders(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Filter out class reminders
            let classReminders = requests.filter { $0.identifier.hasPrefix("class-reminder-") }
            completion(classReminders)
        }
    }
}

/// Class information model
struct ClassInfo {
    let id: String
    let title: String
    let location: String
    let startTime: Date
    let endTime: Date

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}
