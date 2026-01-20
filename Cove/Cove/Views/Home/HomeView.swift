import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyContract.date, order: .reverse) private var contracts: [DailyContract]
    @State private var showMeltdown = false

    private var todaysContract: DailyContract? {
        let today = Calendar.current.startOfDay(for: Date())
        return contracts.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // Stability Bar
                    if let contract = todaysContract {
                        StabilityBarView(score: contract.stabilityScore, progress: contract.progress)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Today's Tasks
                    if let contract = todaysContract, !contract.tasks.isEmpty {
                        todayTasksSection(contract: contract)
                    } else {
                        emptyStateView
                    }
                }
                .padding(.top, Spacing.md)
            }
            .background(Color.cloudWhite)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    MeltdownButton {
                        showMeltdown = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showMeltdown) {
                MeltdownView(isPresented: $showMeltdown)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(greeting)
                .font(.title2)
                .foregroundColor(.mutedText)

            Text("Today's Focus")
                .font(.largeTitle)
                .foregroundColor(.deepText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
    }

    private func todayTasksSection(contract: DailyContract) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Anchor Tasks
            if !contract.anchorTasks.isEmpty {
                sectionHeader("Anchor Tasks", count: contract.anchorTasks.count, max: DailyContract.maxAnchorTasks)

                ForEach(contract.anchorTasks) { task in
                    TaskRowView(task: task) {
                        completeTask(task, in: contract)
                    }
                }
            }

            // Side Quests
            if !contract.sideQuests.isEmpty {
                sectionHeader("Side Quests", count: contract.sideQuests.count, max: DailyContract.maxSideQuests)

                ForEach(contract.sideQuests) { task in
                    TaskRowView(task: task) {
                        completeTask(task, in: contract)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func sectionHeader(_ title: String, count: Int, max: Int) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .foregroundColor(.deepText)

            Spacer()

            Text("\(count)/\(max)")
                .font(.caption)
                .foregroundColor(.mutedText)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 48))
                .foregroundColor(.softWave)

            Text("No tasks yet")
                .font(.title2)
                .foregroundColor(.deepText)

            Text("Head to Capture to add your first task")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func completeTask(_ task: CoveTask, in contract: DailyContract) {
        withAnimation(.spring(response: 0.3)) {
            contract.completeTask(task)
        }
    }
}

// MARK: - Supporting Views

struct TaskRowView: View {
    let task: CoveTask
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .strokeBorder(task.status == .completed ? Color.zenGreen : Color.mistGray, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if task.status == .completed {
                        Circle()
                            .fill(Color.zenGreen)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(task.status == .completed)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.bodyLarge)
                    .foregroundColor(task.status == .completed ? .mutedText : .deepText)
                    .strikethrough(task.status == .completed)

                if let minutes = task.estimatedMinutes {
                    Text("\(minutes) min")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }
            }

            Spacer()

            Text(task.interestLevel.emoji)
                .font(.system(size: 18))
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct MeltdownButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "heart.fill")
                Text("Overwhelmed?")
            }
            .font(.caption)
            .foregroundColor(.coralAlert)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.coralAlert.opacity(0.1))
            .cornerRadius(CornerRadius.full)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [CoveTask.self, DailyContract.self], inMemory: true)
}
