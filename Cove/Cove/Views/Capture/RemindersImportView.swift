import SwiftUI
import SwiftData

/// View for importing Apple Reminders into Cove
/// PRD 6.7.1 - Apple Reminders integration
struct RemindersImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var remindersService = RemindersService()
    @State private var reminders: [ImportableReminder] = []
    @State private var selectedReminders: Set<String> = []
    @State private var isLoading = false
    @State private var importComplete = false
    @State private var importedCount = 0

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Import Reminders")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !selectedReminders.isEmpty {
                            Button("Import (\(selectedReminders.count))") {
                                Task { await importSelected() }
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
        }
        .task {
            await checkAccessAndLoad()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if remindersService.needsPermission {
            permissionView
        } else if !remindersService.hasRemindersAccess {
            accessDeniedView
        } else if isLoading {
            loadingView
        } else if importComplete {
            successView
        } else if reminders.isEmpty {
            emptyView
        } else {
            remindersList
        }
    }

    // MARK: - Permission View

    private var permissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundColor(.calmSea)

            Text("Import from Reminders")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Cove can read your Apple Reminders to help you capture tasks you've already noted elsewhere.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task { await requestAccess() }
            } label: {
                Text("Allow Reminders Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.deepOcean)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Access Denied View

    private var accessDeniedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundColor(.warmSand)

            Text("Reminders Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Please enable Reminders access in Settings to import your reminders.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                openSettings()
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.deepOcean)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading reminders...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.zenGreen)

            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You don't have any incomplete reminders to import.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.deepOcean)
        }
        .padding()
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.zenGreen)

            Text("Import Complete!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Imported \(importedCount) reminder\(importedCount == 1 ? "" : "s") to your capture queue.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.deepOcean)
            .cornerRadius(16)
            .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Reminders List

    private var remindersList: some View {
        List {
            // Select all section
            Section {
                Button {
                    toggleSelectAll()
                } label: {
                    HStack {
                        Image(systemName: selectedReminders.count == reminders.count ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedReminders.count == reminders.count ? .deepOcean : .secondary)
                        Text(selectedReminders.count == reminders.count ? "Deselect All" : "Select All")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(reminders.count) reminders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Grouped by list
            ForEach(groupedReminders.keys.sorted(), id: \.self) { listName in
                Section(header: Text(listName)) {
                    ForEach(groupedReminders[listName] ?? []) { reminder in
                        ReminderRow(
                            reminder: reminder,
                            isSelected: selectedReminders.contains(reminder.id),
                            onToggle: { toggleSelection(reminder) }
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouped Reminders

    private var groupedReminders: [String: [ImportableReminder]] {
        Dictionary(grouping: reminders) { $0.listName }
    }

    // MARK: - Actions

    private func checkAccessAndLoad() async {
        if remindersService.hasRemindersAccess {
            await loadReminders()
        }
    }

    private func requestAccess() async {
        let granted = await remindersService.requestAccess()
        if granted {
            await loadReminders()
        }
    }

    private func loadReminders() async {
        isLoading = true
        reminders = await remindersService.fetchIncompleteReminders()
        isLoading = false
    }

    private func toggleSelection(_ reminder: ImportableReminder) {
        if selectedReminders.contains(reminder.id) {
            selectedReminders.remove(reminder.id)
        } else {
            selectedReminders.insert(reminder.id)
        }
    }

    private func toggleSelectAll() {
        if selectedReminders.count == reminders.count {
            selectedReminders.removeAll()
        } else {
            selectedReminders = Set(reminders.map { $0.id })
        }
    }

    private func importSelected() async {
        isLoading = true

        let toImport = reminders.filter { selectedReminders.contains($0.id) }

        for reminder in toImport {
            let task = CoveTask(
                title: reminder.title,
                description: reminder.notes,
                bucket: .directive,
                status: .pending,
                interestLevel: remindersService.estimateInterestLevel(for: reminder),
                energyRequired: remindersService.estimateEnergyRequired(for: reminder),
                scheduledFor: reminder.dueDate
            )

            modelContext.insert(task)
        }

        do {
            try modelContext.save()
            importedCount = toImport.count
            importComplete = true

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            // Handle error silently for now
        }

        isLoading = false
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Reminder Row

struct ReminderRow: View {
    let reminder: ImportableReminder
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .deepOcean : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        // Priority badge
                        if reminder.priority != .none {
                            HStack(spacing: 2) {
                                Image(systemName: reminder.priority.icon)
                                Text(reminder.priority.rawValue)
                            }
                            .font(.caption2)
                            .foregroundColor(reminder.priority == .high ? .warmSand : .secondary)
                        }

                        // Due date
                        if let formattedDate = reminder.formattedDueDate {
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                Text(formattedDate)
                            }
                            .font(.caption2)
                            .foregroundColor(reminder.isOverdue ? .warmSand : .secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    RemindersImportView()
        .modelContainer(for: CoveTask.self, inMemory: true)
}
