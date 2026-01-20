import SwiftUI
import SwiftData
import EventKit

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var calendarService = CalendarService()
    @State private var selectedDate = Date()
    @State private var showPermissionAlert = false
    @State private var showCalendarPicker = false
    @State private var showScheduleSheet = false
    @State private var taskToSchedule: CoveTask?

    @Query(sort: \CoveTask.createdAt, order: .reverse)
    private var allTasks: [CoveTask]

    private var unscheduledTasks: [CoveTask] {
        allTasks.filter { $0.scheduledFor == nil && $0.status == .pending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if calendarService.needsPermission {
                    permissionRequestView
                } else if calendarService.hasCalendarAccess {
                    calendarContentView
                } else {
                    accessDeniedView
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if calendarService.hasCalendarAccess {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCalendarPicker = true
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.deepOcean)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCalendarPicker) {
                CalendarPickerSheet(
                    calendarService: calendarService,
                    isPresented: $showCalendarPicker
                )
            }
            .sheet(item: $taskToSchedule) { task in
                ScheduleTaskSheet(
                    task: task,
                    calendarService: calendarService,
                    selectedDate: selectedDate,
                    onSchedule: { date in
                        scheduleTask(task, at: date)
                    }
                )
            }
        }
    }

    // MARK: - Permission Request
    private var permissionRequestView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.softWave)

            Text("Calendar Access")
                .font(.title2)
                .foregroundColor(.deepText)

            Text("Cove can sync with your calendar to find available time slots and avoid conflicts.")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                Task {
                    await calendarService.requestAccess()
                }
            } label: {
                Label("Enable Calendar", systemImage: "calendar")
                    .font(.bodyLargeBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.deepOcean)
                    .cornerRadius(CornerRadius.lg)
            }
            .padding(.top, Spacing.md)

            Spacer()
        }
        .background(Color.cloudWhite)
    }

    private var accessDeniedView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.coralAlert)

            Text("Calendar Access Denied")
                .font(.title2)
                .foregroundColor(.deepText)

            Text("Enable calendar access in Settings to use scheduling features.")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.bodyLargeBold)
                    .foregroundColor(.deepOcean)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.deepOcean.opacity(0.1))
                    .cornerRadius(CornerRadius.lg)
            }

            Spacer()
        }
        .background(Color.cloudWhite)
    }

    // MARK: - Calendar Content
    private var calendarContentView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                datePickerSection
                todaysEventsSection
                availableSlotsSection
                unscheduledTasksSection
            }
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.cloudWhite)
        .onAppear {
            calendarService.loadCalendars()
        }
    }

    // MARK: - Date Picker
    private var datePickerSection: some View {
        VStack(spacing: Spacing.md) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.deepOcean)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Today's Events
    private var todaysEventsSection: some View {
        let events = calendarService.fetchEvents(for: selectedDate)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.softWave)
                Text("Existing Events")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
                Text("\(events.count)")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            if events.isEmpty {
                emptyEventsView
            } else {
                ForEach(events, id: \.eventIdentifier) { event in
                    EventRowView(event: event)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var emptyEventsView: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.zenGreen)
            Text("No events scheduled")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.zenGreen.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Available Slots
    private var availableSlotsSection: some View {
        let slots = calendarService.findAvailableSlots(on: selectedDate, duration: 30)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundColor(.zenGreen)
                Text("Available Slots")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
                Text("\(slots.count) found")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            if slots.isEmpty {
                noSlotsView
            } else {
                ForEach(slots) { slot in
                    TimeSlotRow(slot: slot)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var noSlotsView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.warmSand)
            Text("No available slots found")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.warmSand.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Unscheduled Tasks
    private var unscheduledTasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "tray.full")
                    .foregroundColor(.mutedText)
                Text("Unscheduled Tasks")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
                Text("\(unscheduledTasks.count)")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            if unscheduledTasks.isEmpty {
                allScheduledView
            } else {
                ForEach(unscheduledTasks) { task in
                    UnscheduledTaskRow(task: task) {
                        taskToSchedule = task
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var allScheduledView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.zenGreen)
            Text("All tasks are scheduled")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.zenGreen.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Actions
    private func scheduleTask(_ task: CoveTask, at date: Date) {
        task.scheduledFor = date

        Task {
            do {
                _ = try await calendarService.createEvent(for: task, at: date)
            } catch {
                // Calendar event creation failed - task is still scheduled locally
            }
        }

        do {
            try modelContext.save()
        } catch {
            // Failed to persist task schedule
        }
    }
}

// MARK: - Supporting Views

struct EventRowView: View {
    let event: EKEvent

    var body: some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(event.title ?? "Untitled")
                    .font(.bodyMedium)
                    .foregroundColor(.deepText)
                    .lineLimit(1)

                if event.isAllDay {
                    Text("All day")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                } else {
                    Text(formatEventTime(event))
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }
            }

            Spacer()

            if let duration = eventDuration(event) {
                Text(duration)
                    .font(.caption)
                    .foregroundColor(.mutedText)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.mistGray.opacity(0.5))
                    .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }

    private func formatEventTime(_ event: EKEvent) -> String {
        guard let start = event.startDate, let end = event.endDate else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private func eventDuration(_ event: EKEvent) -> String? {
        guard let start = event.startDate, let end = event.endDate else { return nil }
        let minutes = Int(end.timeIntervalSince(start) / 60)
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }
}

struct TimeSlotRow: View {
    let slot: TimeSlot

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "clock")
                .foregroundColor(.zenGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.formattedTimeRange)
                    .font(.bodyMedium)
                    .foregroundColor(.deepText)

                Text("\(slot.formattedDuration) available")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.zenGreen.opacity(0.05))
        .cornerRadius(CornerRadius.md)
    }
}

struct UnscheduledTaskRow: View {
    let task: CoveTask
    let onSchedule: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.bodyMedium)
                    .foregroundColor(.deepText)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    if let minutes = task.estimatedMinutes {
                        Label("\(minutes)m", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.mutedText)
                    }

                    Text(task.energyRequired.emoji)
                        .font(.caption)
                }
            }

            Spacer()

            Button(action: onSchedule) {
                Label("Schedule", systemImage: "calendar.badge.plus")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.deepOcean)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.deepOcean.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}

// MARK: - Calendar Picker Sheet

struct CalendarPickerSheet: View {
    @Bindable var calendarService: CalendarService
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List(calendarService.calendars, id: \.calendarIdentifier) { calendar in
                Button {
                    calendarService.selectCalendar(calendar)
                    isPresented = false
                } label: {
                    HStack {
                        Circle()
                            .fill(Color(cgColor: calendar.cgColor))
                            .frame(width: 12, height: 12)

                        Text(calendar.title)
                            .foregroundColor(.deepText)

                        Spacer()

                        if calendarService.selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier {
                            Image(systemName: "checkmark")
                                .foregroundColor(.deepOcean)
                        }
                    }
                }
            }
            .navigationTitle("Select Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Schedule Task Sheet

struct ScheduleTaskSheet: View {
    let task: CoveTask
    @Bindable var calendarService: CalendarService
    let selectedDate: Date
    let onSchedule: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date
    @State private var showConflictWarning = false

    init(task: CoveTask, calendarService: CalendarService, selectedDate: Date, onSchedule: @escaping (Date) -> Void) {
        self.task = task
        self.calendarService = calendarService
        self.selectedDate = selectedDate
        self.onSchedule = onSchedule

        let suggestedTime = calendarService.suggestTime(for: task, on: selectedDate)
        _selectedTime = State(initialValue: suggestedTime ?? selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                taskInfoSection
                timePickerSection
                suggestedSlotsSection

                if showConflictWarning {
                    conflictWarning
                }

                Spacer()

                scheduleButton
            }
            .padding(Spacing.lg)
            .background(Color.cloudWhite)
            .navigationTitle("Schedule Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedTime) { _, newValue in
                checkForConflicts(at: newValue)
            }
        }
        .presentationDetents([.large])
    }

    private var taskInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(task.title)
                .font(.title3)
                .foregroundColor(.deepText)

            HStack(spacing: Spacing.md) {
                if let minutes = task.estimatedMinutes {
                    Label("\(minutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }

                Label(task.energyRequired.displayName, systemImage: "bolt")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }

    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Select Time")
                .font(.bodyMedium)
                .foregroundColor(.deepText)

            DatePicker(
                "Time",
                selection: $selectedTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .tint(.deepOcean)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }

    private var suggestedSlotsSection: some View {
        let slots = calendarService.findAvailableSlots(
            on: selectedDate,
            duration: task.estimatedMinutes ?? 30
        )

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Pick")
                .font(.bodyMedium)
                .foregroundColor(.deepText)

            if slots.isEmpty {
                Text("No available slots found")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(slots.prefix(5)) { slot in
                            Button {
                                selectedTime = slot.startTime
                            } label: {
                                VStack(spacing: 2) {
                                    Text(formatTime(slot.startTime))
                                        .font(.captionBold)
                                    Text(slot.formattedDuration)
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(isSelected(slot) ? .white : .deepOcean)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(isSelected(slot) ? Color.deepOcean : Color.deepOcean.opacity(0.1))
                                .cornerRadius(CornerRadius.md)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
    }

    private var conflictWarning: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.warmSand)
            Text("This time conflicts with an existing event")
                .font(.caption)
                .foregroundColor(.warmSand)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.warmSand.opacity(0.1))
        .cornerRadius(CornerRadius.md)
    }

    private var scheduleButton: some View {
        Button {
            onSchedule(selectedTime)
            dismiss()
        } label: {
            Label("Schedule Task", systemImage: "calendar.badge.plus")
                .font(.bodyLargeBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.deepOcean)
                .cornerRadius(CornerRadius.lg)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func isSelected(_ slot: TimeSlot) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(selectedTime, equalTo: slot.startTime, toGranularity: .minute)
    }

    private func checkForConflicts(at time: Date) {
        let duration = task.estimatedMinutes ?? 30
        showConflictWarning = calendarService.hasConflict(at: time, duration: duration)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [CoveTask.self, DailyContract.self], inMemory: true)
}
