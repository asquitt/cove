import Foundation
import EventKit

@Observable
final class CalendarService {
    // MARK: - State
    private let eventStore = EKEventStore()
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    private(set) var calendars: [EKCalendar] = []
    private(set) var selectedCalendar: EKCalendar?
    private(set) var isLoading = false
    var error: CalendarError?

    // MARK: - Initialization
    init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                updateAuthorizationStatus()
                if granted {
                    loadCalendars()
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
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    var hasCalendarAccess: Bool {
        authorizationStatus == .fullAccess
    }

    var needsPermission: Bool {
        authorizationStatus == .notDetermined
    }

    // MARK: - Calendar Management
    func loadCalendars() {
        guard hasCalendarAccess else { return }
        calendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }

        if selectedCalendar == nil {
            selectedCalendar = eventStore.defaultCalendarForNewEvents
        }
    }

    func selectCalendar(_ calendar: EKCalendar) {
        selectedCalendar = calendar
    }

    // MARK: - Event Fetching
    func fetchEvents(for date: Date) -> [EKEvent] {
        guard hasCalendarAccess else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard hasCalendarAccess else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Event Creation
    func createEvent(for task: CoveTask, at startTime: Date) async throws -> String {
        guard hasCalendarAccess else {
            throw CalendarError.noAccess
        }

        guard let calendar = selectedCalendar ?? eventStore.defaultCalendarForNewEvents else {
            throw CalendarError.noCalendarSelected
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.startDate = startTime

        let duration = task.estimatedMinutes ?? 30
        event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startTime)
        event.calendar = calendar

        if let description = task.taskDescription {
            event.notes = description
        }

        event.notes = (event.notes ?? "") + "\n\n[Cove Task: \(task.id.uuidString)]"

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.saveFailed(error.localizedDescription)
        }
    }

    func updateEvent(identifier: String, newStart: Date, duration: Int) throws {
        guard hasCalendarAccess else {
            throw CalendarError.noAccess
        }

        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        event.startDate = newStart
        event.endDate = Calendar.current.date(byAdding: .minute, value: duration, to: newStart)

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarError.saveFailed(error.localizedDescription)
        }
    }

    func deleteEvent(identifier: String) throws {
        guard hasCalendarAccess else {
            throw CalendarError.noAccess
        }

        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            throw CalendarError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Conflict Detection
    func findConflicts(at startTime: Date, duration: Int) -> [EKEvent] {
        guard hasCalendarAccess else { return [] }

        guard let endTime = Calendar.current.date(byAdding: .minute, value: duration, to: startTime) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startTime,
            end: endTime,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
    }

    func hasConflict(at startTime: Date, duration: Int) -> Bool {
        !findConflicts(at: startTime, duration: duration).isEmpty
    }

    // MARK: - Available Time Slots
    func findAvailableSlots(
        on date: Date,
        duration: Int,
        workdayStart: Int = 9,
        workdayEnd: Int = 17
    ) -> [TimeSlot] {
        guard hasCalendarAccess else { return [] }

        let calendar = Calendar.current
        var availableSlots: [TimeSlot] = []

        guard let dayStart = calendar.date(
            bySettingHour: workdayStart,
            minute: 0,
            second: 0,
            of: date
        ),
        let dayEnd = calendar.date(
            bySettingHour: workdayEnd,
            minute: 0,
            second: 0,
            of: date
        ) else {
            return []
        }

        let events = fetchEvents(from: dayStart, to: dayEnd)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        var currentTime = dayStart

        for event in events {
            let eventStart = event.startDate ?? currentTime

            let gapMinutes = Int(eventStart.timeIntervalSince(currentTime) / 60)
            if gapMinutes >= duration {
                availableSlots.append(TimeSlot(
                    startTime: currentTime,
                    endTime: eventStart,
                    durationMinutes: gapMinutes
                ))
            }

            if let eventEnd = event.endDate, eventEnd > currentTime {
                currentTime = eventEnd
            }
        }

        let finalGapMinutes = Int(dayEnd.timeIntervalSince(currentTime) / 60)
        if finalGapMinutes >= duration {
            availableSlots.append(TimeSlot(
                startTime: currentTime,
                endTime: dayEnd,
                durationMinutes: finalGapMinutes
            ))
        }

        return availableSlots
    }

    // MARK: - Suggested Times
    func suggestTime(for task: CoveTask, on date: Date) -> Date? {
        let duration = task.estimatedMinutes ?? 30
        let slots = findAvailableSlots(on: date, duration: duration)

        guard let firstSlot = slots.first else { return nil }

        if task.energyRequired == .high {
            let morningSlot = slots.first { slot in
                let hour = Calendar.current.component(.hour, from: slot.startTime)
                return hour >= 9 && hour < 12
            }
            return morningSlot?.startTime ?? firstSlot.startTime
        }

        if task.energyRequired == .low {
            let afternoonSlot = slots.first { slot in
                let hour = Calendar.current.component(.hour, from: slot.startTime)
                return hour >= 14 && hour < 17
            }
            return afternoonSlot?.startTime ?? firstSlot.startTime
        }

        return firstSlot.startTime
    }
}

// MARK: - Supporting Types

struct TimeSlot: Identifiable, Equatable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int

    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var formattedDuration: String {
        if durationMinutes < 60 {
            return "\(durationMinutes)m"
        }
        let hours = durationMinutes / 60
        let mins = durationMinutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }
}

enum CalendarError: LocalizedError {
    case noAccess
    case accessDenied(String)
    case noCalendarSelected
    case eventNotFound
    case saveFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAccess:
            return "Calendar access not granted. Please enable in Settings."
        case .accessDenied(let reason):
            return "Calendar access denied: \(reason)"
        case .noCalendarSelected:
            return "No calendar selected for creating events."
        case .eventNotFound:
            return "Calendar event not found."
        case .saveFailed(let reason):
            return "Failed to save event: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete event: \(reason)"
        }
    }
}
