import SwiftUI
import SwiftData

/// View for managing Cold Storage (Someday list)
/// PRD 6.4.3 - Archive ignored goals and periodically suggest revival
struct ColdStorageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allTasks: [CoveTask]

    private var coldStorageTasks: [CoveTask] {
        allTasks.filter { $0.status == .coldStorage }
            .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }
    }
    @State private var coldStorageService = ColdStorageService()
    @State private var selectedTask: CoveTask?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if coldStorageTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Someday")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !coldStorageTasks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        statsButton
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.mistGray)

            Text("Cold Storage is Empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.deepText)

            Text("Tasks that get ignored 3 times will be offered for archive here. They'll resurface later when the time feels right.")
                .font(.subheadline)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cloudWhite)
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            Section {
                ForEach(coldStorageTasks) { task in
                    ColdStorageTaskRow(task: task) {
                        reviveTask(task)
                    } onDelete: {
                        selectedTask = task
                        showDeleteConfirmation = true
                    }
                }
            } header: {
                Text("\(coldStorageTasks.count) archived \(coldStorageTasks.count == 1 ? "task" : "tasks")")
            } footer: {
                Text("Swipe left to permanently delete. Tap Revive to bring back to your active tasks.")
                    .font(.caption)
            }
        }
        .listStyle(.insetGrouped)
        .confirmationDialog(
            "Delete from Cold Storage?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                if let task = selectedTask {
                    deleteTask(task)
                }
            }
            Button("Cancel", role: .cancel) {
                selectedTask = nil
            }
        } message: {
            Text("This will permanently remove the task. This cannot be undone.")
        }
    }

    // MARK: - Stats Button

    private var statsButton: some View {
        Menu {
            let stats = coldStorageService.getStatistics(from: coldStorageTasks)
            Text("Total: \(stats.totalArchived)")
            if let avgAge = stats.formattedAverageAge {
                Text("Average age: \(avgAge)")
            }
        } label: {
            Image(systemName: "chart.bar")
        }
    }

    // MARK: - Actions

    private func reviveTask(_ task: CoveTask) {
        withAnimation {
            coldStorageService.reviveTask(task)
        }
    }

    private func deleteTask(_ task: CoveTask) {
        withAnimation {
            coldStorageService.deleteFromColdStorage(task, context: modelContext)
        }
        selectedTask = nil
    }
}

// MARK: - Task Row

struct ColdStorageTaskRow: View {
    let task: CoveTask
    let onRevive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .foregroundColor(.deepText)

                HStack(spacing: 8) {
                    if let archivedAt = task.archivedAt {
                        Text("Archived \(archivedAt, format: .relative(presentation: .named))")
                            .font(.caption)
                            .foregroundColor(.mutedText)
                    }

                    Text(task.interestLevel.emoji)
                        .font(.caption)
                }
            }

            Spacer()

            Button(action: onRevive) {
                Text("Revive")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.calmSea)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Archive Suggestion Alert

struct ColdStorageSuggestionView: View {
    let task: CoveTask
    let onArchive: () -> Void
    let onKeep: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 40))
                .foregroundColor(.softWave)

            Text("Archive this task?")
                .font(.headline)
                .foregroundColor(.deepText)

            Text("You've passed on \"\(task.title)\" \(task.ignoreCount) times. Want to move it to your Someday list?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("No shame - it'll come back around when the time is right.")
                .font(.caption)
                .foregroundColor(.mutedText)
                .italic()

            HStack(spacing: 16) {
                Button(action: onKeep) {
                    Text("Keep Active")
                        .font(.subheadline)
                        .foregroundColor(.calmSea)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.calmSea.opacity(0.1))
                        .cornerRadius(20)
                }

                Button(action: onArchive) {
                    Text("Archive It")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.calmSea)
                        .cornerRadius(20)
                }
            }
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

// MARK: - Revival Suggestion View

struct RevivalSuggestionView: View {
    let task: CoveTask
    let onRevive: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(.warmSand)

            Text("Remember this idea?")
                .font(.headline)
                .foregroundColor(.deepText)

            Text("\"\(task.title)\"")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.calmSea)
                .multilineTextAlignment(.center)

            if let archivedAt = task.archivedAt {
                Text("Archived \(archivedAt, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            HStack(spacing: 16) {
                Button(action: onDismiss) {
                    Text("Not Yet")
                        .font(.subheadline)
                        .foregroundColor(.mutedText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.mistGray.opacity(0.5))
                        .cornerRadius(20)
                }

                Button(action: onRevive) {
                    Text("Revive It!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.zenGreen)
                        .cornerRadius(20)
                }
            }
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

#Preview {
    ColdStorageView()
        .modelContainer(for: CoveTask.self, inMemory: true)
}
