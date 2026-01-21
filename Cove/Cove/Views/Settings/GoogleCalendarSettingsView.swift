import SwiftUI

/// Settings view for Google Calendar integration
struct GoogleCalendarSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var calendarService = GoogleCalendarService()
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                connectionSection

                if calendarService.isConnected {
                    syncSection
                    eventsSection
                }

                infoSection
            }
            .navigationTitle("Google Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section {
            if calendarService.isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.zenGreen)
                    Text("Connected")
                        .foregroundColor(.deepText)
                    Spacer()
                    Button("Disconnect") {
                        calendarService.disconnect()
                    }
                    .foregroundColor(.coralAlert)
                }
            } else {
                Button {
                    Task {
                        await connectCalendar()
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(.calmSea)
                        Text("Connect Google Calendar")
                        Spacer()
                        if calendarService.isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(calendarService.isLoading)
            }
        } header: {
            Text("Connection")
        } footer: {
            Text("Connect your Google Calendar to see your schedule alongside your tasks.")
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        Section {
            Toggle("Show calendar events", isOn: .constant(true))

            Toggle("Auto-block task time", isOn: .constant(false))

            Picker("Default event duration", selection: .constant(30)) {
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("60 minutes").tag(60)
            }
        } header: {
            Text("Sync Settings")
        }
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        Section {
            if calendarService.events.isEmpty {
                Button {
                    Task {
                        await fetchEvents()
                    }
                } label: {
                    HStack {
                        Text("Fetch Today's Events")
                        Spacer()
                        if calendarService.isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(calendarService.isLoading)
            } else {
                ForEach(calendarService.events) { event in
                    EventRow(event: event)
                }
            }
        } header: {
            Text("Today's Events")
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("View your schedule", systemImage: "eye")
                Label("Block time for tasks", systemImage: "clock.badge.checkmark")
                Label("Avoid double-booking", systemImage: "calendar.badge.exclamationmark")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        } header: {
            Text("What you can do")
        }
    }

    // MARK: - Actions

    @MainActor
    private func connectCalendar() async {
        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                errorMessage = "Could not get window for authentication"
                showingError = true
                return
            }

            try await calendarService.authenticate(from: window)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func fetchEvents() async {
        do {
            _ = try await calendarService.fetchTodayEvents()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: GoogleCalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.calmSea)
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.deepText)

                HStack(spacing: 4) {
                    if event.isAllDay {
                        Text("All day")
                    } else {
                        Text(event.startTime, style: .time)
                        Text("-")
                        Text(event.endTime, style: .time)
                    }
                }
                .font(.caption)
                .foregroundColor(.mutedText)
            }

            Spacer()

            if !event.isAllDay {
                Text("\(event.durationMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.mistGray.opacity(0.5))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Calendar Events Card (for HomeView)

struct CalendarEventsCard: View {
    @State private var calendarService = GoogleCalendarService()
    @State private var isExpanded = false

    var body: some View {
        if calendarService.isConnected && !calendarService.events.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.calmSea)
                        Text("Today's Schedule")
                            .font(.headline)
                            .foregroundColor(.deepText)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.mutedText)
                    }
                }

                if isExpanded {
                    ForEach(calendarService.events.prefix(5)) { event in
                        HStack {
                            Circle()
                                .fill(Color.calmSea)
                                .frame(width: 8, height: 8)
                            Text(event.title)
                                .font(.subheadline)
                                .foregroundColor(.deepText)
                            Spacer()
                            if !event.isAllDay {
                                Text(event.startTime, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.mutedText)
                            }
                        }
                    }

                    if calendarService.events.count > 5 {
                        Text("+\(calendarService.events.count - 5) more")
                            .font(.caption)
                            .foregroundColor(.mutedText)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .task {
                try? await calendarService.fetchTodayEvents()
            }
        }
    }
}

#Preview {
    GoogleCalendarSettingsView()
}
