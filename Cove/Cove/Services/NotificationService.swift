import Foundation
import UserNotifications

/// Service for managing local notifications for task reminders
actor NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Permission Handling

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Task Reminders

    func scheduleTaskReminder(
        taskId: UUID,
        title: String,
        body: String,
        at date: Date
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": taskId.uuidString]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task-\(taskId.uuidString)",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelTaskReminder(taskId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["task-\(taskId.uuidString)"])
    }

    // MARK: - Daily Contract Reminders

    func scheduleDailyContractReminder(at hour: Int, minute: Int = 0) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Time to plan your day"
        content.body = "Set up today's contract with 3 anchor tasks and 2 side quests."
        content.sound = .default
        content.categoryIdentifier = "CONTRACT_REMINDER"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-contract-reminder",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyContractReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily-contract-reminder"])
    }

    // MARK: - Streak Reminders

    func scheduleStreakReminder(currentStreak: Int, at hour: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Keep your streak alive!"
        content.body = "You're on a \(currentStreak)-day streak. Complete a task to keep it going!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"

        var components = DateComponents()
        components.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "streak-reminder",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelStreakReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["streak-reminder"])
    }

    // MARK: - Meltdown Check-in

    func scheduleMeltdownCheckIn(afterMinutes minutes: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "How are you feeling?"
        content.body = "It's been \(minutes) minutes since your meltdown. Take a moment to check in with yourself."
        content.sound = .default
        content.categoryIdentifier = "MELTDOWN_CHECKIN"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "meltdown-checkin",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Gentle Nudges

    func scheduleGentleNudge(
        taskId: UUID,
        taskTitle: String,
        minutesFromNow: Int
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Gentle nudge"
        content.body = "Ready to work on '\(taskTitle)'?"
        content.sound = .default
        content.categoryIdentifier = "GENTLE_NUDGE"
        content.userInfo = ["taskId": taskId.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutesFromNow * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "nudge-\(taskId.uuidString)",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelGentleNudge(taskId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["nudge-\(taskId.uuidString)"])
    }

    // MARK: - Clear All

    func clearAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func clearAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) async {
        try? await UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func clearBadge() async {
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        let taskActions = [
            UNNotificationAction(
                identifier: "MARK_COMPLETE",
                title: "Mark Complete",
                options: [.foreground]
            ),
            UNNotificationAction(
                identifier: "SNOOZE_15",
                title: "Snooze 15 min",
                options: []
            )
        ]

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: taskActions,
            intentIdentifiers: []
        )

        let contractCategory = UNNotificationCategory(
            identifier: "CONTRACT_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "OPEN_CONTRACT",
                    title: "Set Up Contract",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: []
        )

        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_TASKS",
                    title: "View Tasks",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: []
        )

        let meltdownCategory = UNNotificationCategory(
            identifier: "MELTDOWN_CHECKIN",
            actions: [
                UNNotificationAction(
                    identifier: "FEELING_BETTER",
                    title: "Feeling Better",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "NEED_MORE_TIME",
                    title: "Need More Time",
                    options: []
                )
            ],
            intentIdentifiers: []
        )

        let nudgeCategory = UNNotificationCategory(
            identifier: "GENTLE_NUDGE",
            actions: [
                UNNotificationAction(
                    identifier: "START_TASK",
                    title: "Start Now",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SNOOZE_30",
                    title: "Later",
                    options: []
                )
            ],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            taskCategory,
            contractCategory,
            streakCategory,
            meltdownCategory,
            nudgeCategory
        ])
    }
}

// MARK: - Notification Settings Model

struct NotificationSettings: Codable {
    var dailyReminderEnabled: Bool = true
    var dailyReminderHour: Int = 9
    var dailyReminderMinute: Int = 0
    var streakReminderEnabled: Bool = true
    var streakReminderHour: Int = 20
    var taskRemindersEnabled: Bool = true
    var gentleNudgesEnabled: Bool = true
    var meltdownCheckInsEnabled: Bool = true

    static let `default` = NotificationSettings()
}
