import SwiftUI
import SwiftData

struct ContractView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyContract.date, order: .reverse) private var contracts: [DailyContract]
    @Query(filter: #Predicate<CoveTask> { $0.contract == nil && $0.status == .pending })
    private var unassignedTasks: [CoveTask]

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

                    if let contract = todaysContract {
                        contractContent(contract)
                    } else {
                        createContractPrompt
                    }
                }
                .padding(.top, Spacing.md)
            }
            .background(Color.cloudWhite)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Daily Contract")
                .font(.largeTitle)
                .foregroundColor(.deepText)

            Text(dateString)
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
    }

    private func contractContent(_ contract: DailyContract) -> some View {
        VStack(spacing: Spacing.lg) {
            // Reality Check
            realityCheckCard(contract)

            // Anchor Tasks Section
            contractSection(
                title: "Anchor Tasks",
                subtitle: "Your main focus for today",
                tasks: contract.anchorTasks,
                maxCount: DailyContract.maxAnchorTasks,
                isAnchor: true,
                contract: contract
            )

            // Side Quests Section
            contractSection(
                title: "Side Quests",
                subtitle: "If time and energy permit",
                tasks: contract.sideQuests,
                maxCount: DailyContract.maxSideQuests,
                isAnchor: false,
                contract: contract
            )

            // Unassigned Tasks
            if !unassignedTasks.isEmpty {
                unassignedSection(contract: contract)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func realityCheckCard(_ contract: DailyContract) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.softWave)
                Text("Reality Check")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
            }

            HStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Estimated")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                    Text("\(contract.totalEstimatedMinutes) min")
                        .font(.title2)
                        .foregroundColor(.deepText)
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Tasks")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                    Text("\(contract.tasks.count)")
                        .font(.title2)
                        .foregroundColor(.deepText)
                }

                Spacer()

                // Status indicator
                statusBadge(contract.status)
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func statusBadge(_ status: ContractStatus) -> some View {
        Text(status.displayName)
            .font(.captionBold)
            .foregroundColor(statusColor(status))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(statusColor(status).opacity(0.1))
            .cornerRadius(CornerRadius.full)
    }

    private func statusColor(_ status: ContractStatus) -> Color {
        switch status {
        case .draft: return .mutedText
        case .active: return .softWave
        case .completed: return .zenGreen
        case .abandoned: return .coralAlert
        }
    }

    private func contractSection(
        title: String,
        subtitle: String,
        tasks: [CoveTask],
        maxCount: Int,
        isAnchor: Bool,
        contract: DailyContract
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3)
                        .foregroundColor(.deepText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }

                Spacer()

                Text("\(tasks.count)/\(maxCount)")
                    .font(.captionBold)
                    .foregroundColor(tasks.count >= maxCount ? .warmSand : .mutedText)
            }

            if tasks.isEmpty {
                emptySlot(isAnchor: isAnchor)
            } else {
                ForEach(tasks) { task in
                    ContractTaskCard(task: task) {
                        removeTask(task, from: contract)
                    }
                }
            }
        }
    }

    private func emptySlot(isAnchor: Bool) -> some View {
        HStack {
            Image(systemName: "plus.circle.dashed")
                .foregroundColor(.mistGray)
            Text(isAnchor ? "Add an anchor task" : "Add a side quest")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.mistGray.opacity(0.3))
        .cornerRadius(CornerRadius.md)
    }

    private func unassignedSection(contract: DailyContract) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Available Tasks")
                .font(.title3)
                .foregroundColor(.deepText)

            ForEach(unassignedTasks) { task in
                UnassignedTaskCard(task: task) { isAnchor in
                    addTaskToContract(task, asAnchor: isAnchor, contract: contract)
                }
            }
        }
    }

    private var createContractPrompt: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.softWave)

            Text("No contract for today")
                .font(.title2)
                .foregroundColor(.deepText)

            Text("Create today's contract to get started")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)

            Button(action: createTodaysContract) {
                Text("Create Contract")
                    .font(.bodyLargeBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.deepOcean)
                    .cornerRadius(CornerRadius.lg)
            }
        }
        .padding(Spacing.xl)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func createTodaysContract() {
        let contract = DailyContract()
        modelContext.insert(contract)
    }

    private func addTaskToContract(_ task: CoveTask, asAnchor: Bool, contract: DailyContract) {
        task.isAnchorTask = asAnchor
        do {
            try contract.addTask(task)
        } catch {
            // Handle error - show alert
        }
    }

    private func removeTask(_ task: CoveTask, from contract: DailyContract) {
        contract.removeTask(task)
    }
}

struct ContractTaskCard: View {
    let task: CoveTask
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.bodyLarge)
                    .foregroundColor(.deepText)

                HStack(spacing: Spacing.sm) {
                    if let minutes = task.estimatedMinutes {
                        Label("\(minutes) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.mutedText)
                    }

                    Text(task.interestLevel.emoji)
                    Text(task.energyRequired.emoji)
                }
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.mistGray)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct UnassignedTaskCard: View {
    let task: CoveTask
    let onAdd: (Bool) -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.title)
                    .font(.bodyMedium)
                    .foregroundColor(.deepText)

                if let minutes = task.estimatedMinutes {
                    Text("\(minutes) min")
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }
            }

            Spacer()

            HStack(spacing: Spacing.sm) {
                Button("Anchor") {
                    onAdd(true)
                }
                .font(.caption)
                .foregroundColor(.deepOcean)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.deepOcean.opacity(0.1))
                .cornerRadius(CornerRadius.sm)

                Button("Side") {
                    onAdd(false)
                }
                .font(.caption)
                .foregroundColor(.softWave)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.softWave.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.md)
        .background(Color.mistGray.opacity(0.3))
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    ContractView()
        .modelContainer(for: [CoveTask.self, DailyContract.self], inMemory: true)
}
