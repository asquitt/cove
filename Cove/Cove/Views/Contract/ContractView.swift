import SwiftUI
import SwiftData

struct ContractView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ContractViewModel()
    @State private var gamificationService = GamificationService()
    @State private var patternService = PatternService()
    @State private var showCompletionCelebration = false
    @State private var lastCompletedTask: CoveTask?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showMeltdown = false
    @State private var showLevelUp = false
    @State private var levelUpResult: LevelUpResult?
    @State private var showAchievement = false
    @State private var unlockedAchievement: Achievement?
    @State private var streakBonus: Int = 0
    @State private var companionService = AICompanionService()
    @State private var inactivitySeconds: TimeInterval = 0
    @State private var inactivityTimer: Timer?

    @Query(sort: \DailyContract.date, order: .reverse)
    private var contracts: [DailyContract]

    @Query(sort: \CoveTask.createdAt, order: .reverse)
    private var allTasks: [CoveTask]

    @Query(sort: \UserProfile.createdAt)
    private var profiles: [UserProfile]

    private var userProfile: UserProfile? {
        profiles.first
    }

    private var unassignedTasks: [CoveTask] {
        allTasks.filter { $0.contract == nil && $0.status == .pending }
    }

    private var todaysContract: DailyContract? {
        let today = Calendar.current.startOfDay(for: Date())
        return contracts.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        headerSection

                        if let contract = todaysContract {
                            contractContent(contract)
                        } else {
                            createContractPrompt
                        }
                    }
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
                .background(Color.cloudWhite)
                .navigationBarTitleDisplayMode(.inline)

                // Completion celebration overlay
                if showCompletionCelebration, let task = lastCompletedTask {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showCompletionCelebration = false
                        }

                    CompletionCelebrationView(task: task, streakBonus: streakBonus) {
                        showCompletionCelebration = false
                        checkForPendingCelebrations()
                    }
                }

                // Level up celebration overlay
                if showLevelUp, let result = levelUpResult {
                    LevelUpCelebrationView(
                        oldLevel: result.oldLevel,
                        newLevel: result.newLevel
                    ) {
                        showLevelUp = false
                        levelUpResult = nil
                        checkForPendingAchievements()
                    }
                }

                // Achievement unlock overlay
                if showAchievement, let achievement = unlockedAchievement {
                    AchievementUnlockView(achievement: achievement) {
                        showAchievement = false
                        unlockedAchievement = nil
                        checkForPendingAchievements()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
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
            .overlay {
                AICompanionOverlay(
                    message: companionService.microCoachingMessage,
                    isVisible: companionService.showMicroCoaching,
                    onDismiss: {
                        companionService.dismissMicroCoaching()
                        resetInactivityTimer()
                    }
                )
            }
            .onAppear {
                startInactivityTimer()
            }
            .onDisappear {
                stopInactivityTimer()
            }
        }
    }

    // MARK: - Inactivity Detection (PRD 6.6.2)
    private func startInactivityTimer() {
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            inactivitySeconds += 10
            if inactivitySeconds >= 45 && !companionService.showMicroCoaching {
                companionService.triggerMicroCoaching(MicroCoachingMessage.stuckOnTask.randomMessage)
            }
        }
    }

    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }

    private func resetInactivityTimer() {
        inactivitySeconds = 0
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Daily Contract")
                    .font(.largeTitle)
                    .foregroundColor(.deepText)

                Text(dateString)
                    .font(.bodyMedium)
                    .foregroundColor(.mutedText)
            }

            Spacer()

            if let contract = todaysContract {
                ProgressRingView(progress: contract.progress, size: 50)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Contract Content
    private func contractContent(_ contract: DailyContract) -> some View {
        VStack(spacing: Spacing.lg) {
            // Reality Check Card
            realityCheckCard(contract)

            // Stability Bar
            StabilityBarView(score: contract.stabilityScore, progress: contract.progress)
                .padding(.horizontal, Spacing.lg)

            // Anchor Tasks Section
            taskSection(
                title: "Anchor Tasks",
                subtitle: "Your main focus today",
                icon: "anchor",
                tasks: contract.anchorTasks,
                maxCount: DailyContract.maxAnchorTasks,
                isAnchor: true,
                contract: contract
            )

            // Side Quests Section
            taskSection(
                title: "Side Quests",
                subtitle: "If time and energy permit",
                icon: "sparkles",
                tasks: contract.sideQuests,
                maxCount: DailyContract.maxSideQuests,
                isAnchor: false,
                contract: contract
            )

            // Unassigned Tasks
            if !unassignedTasks.isEmpty {
                unassignedSection(contract: contract)
            }

            // Contract Complete State
            if contract.isComplete {
                contractCompleteCard
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Reality Check Card
    private func realityCheckCard(_ contract: DailyContract) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundColor(.softWave)
                Text("Reality Check")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
                statusBadge(contract.status)
            }

            HStack(spacing: Spacing.xl) {
                statItem(
                    label: "Estimated",
                    value: formatDuration(contract.totalEstimatedMinutes),
                    icon: "clock"
                )

                Divider()
                    .frame(height: 40)

                statItem(
                    label: "With Buffer",
                    value: formatDuration(applyPessimism(contract.totalEstimatedMinutes)),
                    icon: "shield"
                )

                Divider()
                    .frame(height: 40)

                statItem(
                    label: "Done",
                    value: "\(contract.completedTasks.count)/\(contract.tasks.count)",
                    icon: "checkmark.circle"
                )
            }

            // Warning if over-scheduled
            if contract.totalEstimatedMinutes > 360 {
                overScheduledWarning
            }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(.mutedText)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.deepText)
        }
    }

    private var overScheduledWarning: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.warmSand)
            Text("You might be over-scheduling. Consider removing a task.")
                .font(.caption)
                .foregroundColor(.warmSand)
        }
        .padding(Spacing.sm)
        .background(Color.warmSand.opacity(0.1))
        .cornerRadius(CornerRadius.sm)
    }

    // MARK: - Task Section
    private func taskSection(
        title: String,
        subtitle: String,
        icon: String,
        tasks: [CoveTask],
        maxCount: Int,
        isAnchor: Bool,
        contract: DailyContract
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isAnchor ? .deepOcean : .softWave)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3)
                        .foregroundColor(.deepText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.mutedText)
                }

                Spacer()

                // Counter badge
                Text("\(tasks.count)/\(maxCount)")
                    .font(.captionBold)
                    .foregroundColor(tasks.count >= maxCount ? .warmSand : .mutedText)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(tasks.count >= maxCount ? Color.warmSand.opacity(0.1) : Color.mistGray.opacity(0.5))
                    .cornerRadius(CornerRadius.full)
            }

            // Task cards
            if tasks.isEmpty {
                emptySlot(isAnchor: isAnchor)
            } else {
                ForEach(tasks) { task in
                    TaskCardView(
                        task: task,
                        onComplete: { completeTask(task, in: contract) },
                        onStart: { startTask(task) },
                        onRemove: { removeTask(task, from: contract) }
                    )
                }
            }
        }
    }

    private func emptySlot(isAnchor: Bool) -> some View {
        HStack {
            Image(systemName: "plus.circle.dashed")
                .foregroundColor(.mutedText.opacity(0.5))
            Text(isAnchor ? "Add an anchor task from below" : "Add a side quest from below")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.mistGray.opacity(0.3))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Unassigned Section
    private func unassignedSection(contract: DailyContract) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "tray.full")
                    .foregroundColor(.mutedText)
                Text("Available Tasks")
                    .font(.title3)
                    .foregroundColor(.deepText)
                Spacer()
                Text("\(unassignedTasks.count)")
                    .font(.caption)
                    .foregroundColor(.mutedText)
            }

            ForEach(unassignedTasks) { task in
                UnassignedTaskCard(
                    task: task,
                    canAddAnchor: contract.canAddAnchorTask,
                    canAddSideQuest: contract.canAddSideQuest
                ) { isAnchor in
                    addTaskToContract(task, asAnchor: isAnchor, contract: contract)
                }
            }
        }
    }

    // MARK: - Contract Complete Card
    private var contractCompleteCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundColor(.warmSand)

            Text("Contract Complete!")
                .font(.title2)
                .foregroundColor(.deepText)

            Text("You crushed it today. Time to rest.")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.zenGreen.opacity(0.1), Color.warmSand.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Create Contract Prompt
    private var createContractPrompt: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.softWave)

            Text("No contract for today")
                .font(.title2)
                .foregroundColor(.deepText)

            Text("Create your daily contract to commit to 3 anchor tasks and 2 side quests")
                .font(.bodyMedium)
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)

            Button(action: createTodaysContract) {
                Label("Create Contract", systemImage: "plus.circle.fill")
                    .font(.bodyLargeBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.deepOcean)
                    .cornerRadius(CornerRadius.lg)
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: contracts.count)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Status Badge
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

    // MARK: - Helpers
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    private func applyPessimism(_ minutes: Int) -> Int {
        Int(Double(minutes) * Constants.defaultPessimismMultiplier)
    }

    // MARK: - Actions
    private func createTodaysContract() {
        let contract = DailyContract()
        modelContext.insert(contract)
    }

    private func addTaskToContract(_ task: CoveTask, asAnchor: Bool, contract: DailyContract) {
        task.isAnchorTask = asAnchor
        resetInactivityTimer()
        do {
            try contract.addTask(task)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func removeTask(_ task: CoveTask, from contract: DailyContract) {
        withAnimation(.spring(response: 0.3)) {
            contract.removeTask(task)
        }
    }

    private func completeTask(_ task: CoveTask, in contract: DailyContract) {
        resetInactivityTimer()
        contract.completeTask(task)
        lastCompletedTask = task

        // Process gamification
        if let profile = userProfile {
            // Check for streak bonus before processing
            streakBonus = gamificationService.hasStreakBonus(profile: profile) ? gamificationService.streakBonusAmount() : 0

            // Process completion and check for level up
            if let result = gamificationService.processTaskCompletion(task: task, profile: profile) {
                levelUpResult = result
            }

            // Record pattern for learning
            patternService.recordTaskCompletion(task: task, profile: profile)

            // Check if contract is complete
            if contract.isComplete {
                gamificationService.processContractCompletion(profile: profile)
            }
        }

        showCompletionCelebration = true
    }

    private func startTask(_ task: CoveTask) {
        resetInactivityTimer()
        task.status = .inProgress
        task.scheduledFor = Date()
    }

    private func checkForPendingCelebrations() {
        // Check for level up first
        if let result = gamificationService.pendingLevelUp {
            levelUpResult = result
            gamificationService.clearPendingLevelUp()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showLevelUp = true
            }
        } else {
            checkForPendingAchievements()
        }
    }

    private func checkForPendingAchievements() {
        if let achievement = gamificationService.popNextAchievement() {
            unlockedAchievement = achievement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showAchievement = true
            }
        }
    }
}

// MARK: - Unassigned Task Card
struct UnassignedTaskCard: View {
    let task: CoveTask
    let canAddAnchor: Bool
    let canAddSideQuest: Bool
    let onAdd: (Bool) -> Void

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

                    Text(task.interestLevel.emoji)
                        .font(.caption)

                    Text(task.energyRequired.emoji)
                        .font(.caption)
                }
            }

            Spacer()

            VStack(spacing: Spacing.xs) {
                Button(action: { onAdd(true) }) {
                    Text("Anchor")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(canAddAnchor ? .deepOcean : .mutedText)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(canAddAnchor ? Color.deepOcean.opacity(0.1) : Color.mistGray.opacity(0.3))
                        .cornerRadius(CornerRadius.sm)
                }
                .disabled(!canAddAnchor)

                Button(action: { onAdd(false) }) {
                    Text("Side Quest")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(canAddSideQuest ? .softWave : .mutedText)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(canAddSideQuest ? Color.softWave.opacity(0.1) : Color.mistGray.opacity(0.3))
                        .cornerRadius(CornerRadius.sm)
                }
                .disabled(!canAddSideQuest)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}

#Preview {
    ContractView()
        .modelContainer(for: [CoveTask.self, DailyContract.self], inMemory: true)
}
