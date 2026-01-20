import Foundation
import EventKit

/// Service for reading Apple Reminders and importing them into Cove
/// PRD 6.7.1 - Apple Reminders integration (read-only)
@Observable
final class RemindersService {
    // MARK: - State
    private let eventStore = EKEventStore()
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    private(set) var reminderLists: [EKCalendar] = []
    private(set) var isLoading = false
    var error: RemindersError?

    // MARK: - Initialization
    init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            await MainActor.run {
                updateAuthorizationStatus()
                if granted {
                    loadReminderLists()
                }
            }
            return granted
        } catch {
            await MainActor.run {
                self.error = .accessDenied(error.localizedDescription)
            }
            return false
        }
    }

    private func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    var hasRemindersAccess: Bool {
        authorizationStatus == .fullAccess
    }

    var needsPermission: Bool {
        authorizationStatus == .notDetermined
    }

    // MARK: - Reminder Lists
    func loadReminderLists() {
        guard hasRemindersAccess else { return }
        reminderLists = eventStore.calendars(for: .reminder)
            .sorted { $0.title < $1.title }
    }

    // MARK: - Fetch Reminders
    func fetchIncompleteReminders() async -> [ImportableReminder] {
        guard hasRemindersAccess else { return [] }

        isLoading = true
        defer { isLoading = false }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: reminderLists
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let importable = (reminders ?? []).map { reminder in
                    ImportableReminder(
                        id: reminder.calendarItemIdentifier,
                        title: reminder.title ?? "Untitled Reminder",
                        notes: reminder.notes,
                        dueDate: reminder.dueDateComponents?.date,
                        priority: self.mapPriority(reminder.priority),
                        listName: reminder.calendar?.title ?? "Reminders"
                    )
                }
                continuation.resume(returning: importable)
            }
        }
    }

    func fetchReminders(from list: EKCalendar) async -> [ImportableReminder] {
        guard hasRemindersAccess else { return [] }

        isLoading = true
        defer { isLoading = false }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: [list]
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let importable = (reminders ?? []).map { reminder in
                    ImportableReminder(
                        id: reminder.calendarItemIdentifier,
                        title: reminder.title ?? "Untitled Reminder",
                        notes: reminder.notes,
                        dueDate: reminder.dueDateComponents?.date,
                        priority: self.mapPriority(reminder.priority),
                        listName: reminder.calendar?.title ?? "Reminders"
                    )
                }
                continuation.resume(returning: importable)
            }
        }
    }

    func fetchRemindersWithDueDate(from startDate: Date, to endDate: Date) async -> [ImportableReminder] {
        guard hasRemindersAccess else { return [] }

        isLoading = true
        defer { isLoading = false }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: startDate,
            ending: endDate,
            calendars: reminderLists
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let importable = (reminders ?? []).map { reminder in
                    ImportableReminder(
                        id: reminder.calendarItemIdentifier,
                        title: reminder.title ?? "Untitled Reminder",
                        notes: reminder.notes,
                        dueDate: reminder.dueDateComponents?.date,
                        priority: self.mapPriority(reminder.priority),
                        listName: reminder.calendar?.title ?? "Reminders"
                    )
                }
                continuation.resume(returning: importable)
            }
        }
    }

    // MARK: - Helper Methods
    private func mapPriority(_ priority: Int) -> ImportableReminder.Priority {
        switch priority {
        case 1...4: return .high
        case 5: return .medium
        case 6...9: return .low
        default: return .none
        }
    }

    func estimateInterestLevel(for reminder: ImportableReminder) -> InterestLevel {
        // Use priority and urgency as proxies for interest
        if reminder.priority == .high {
            return .high
        }
        if let dueDate = reminder.dueDate,
           dueDate < Date().addingTimeInterval(86400 * 2) { // Within 2 days
            return .high
        }
        if reminder.priority == .medium {
            return .medium
        }
        return .low
    }

    func estimateEnergyRequired(for reminder: ImportableReminder) -> EnergyLevel {
        let title = reminder.title.lowercased()

        // High energy keywords
        let highEnergyKeywords = ["call", "meeting", "present", "write", "create", "design", "build"]
        if highEnergyKeywords.contains(where: { title.contains($0) }) {
            return .high
        }

        // Low energy keywords
        let lowEnergyKeywords = ["buy", "pick up", "send", "email", "text", "check", "review"]
        if lowEnergyKeywords.contains(where: { title.contains($0) }) {
            return .low
        }

        return .medium
    }
}

// MARK: - Importable Reminder

struct ImportableReminder: Identifiable, Equatable {
    let id: String
    let title: String
    let notes: String?
    let dueDate: Date?
    let priority: Priority
    let listName: String

    enum Priority: String, CaseIterable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case none = "None"

        var icon: String {
            switch self {
            case .high: return "exclamationmark.3"
            case .medium: return "exclamationmark.2"
            case .low: return "exclamationmark"
            case .none: return "minus"
            }
        }

        var color: String {
            switch self {
            case .high: return "warmSand"
            case .medium: return "calmSea"
            case .low: return "mistGray"
            case .none: return "mistGray"
            }
        }
    }

    var formattedDueDate: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date()
    }
}

// MARK: - Errors

enum RemindersError: LocalizedError {
    case noAccess
    case accessDenied(String)
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAccess:
            return "Reminders access not granted. Please enable in Settings."
        case .accessDenied(let reason):
            return "Reminders access denied: \(reason)"
        case .fetchFailed(let reason):
            return "Failed to fetch reminders: \(reason)"
        }
    }
}
