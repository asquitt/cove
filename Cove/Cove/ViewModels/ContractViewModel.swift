import Foundation
import SwiftData

@Observable
final class ContractViewModel {
    // MARK: - State
    var todaysContract: DailyContract?
    var unassignedTasks: [CoveTask] = []
    var errorMessage: String?
    var showError = false
    var showCompletionCelebration = false
    var lastCompletedTask: CoveTask?

    private var modelContext: ModelContext?

    // MARK: - Initialization
    func configure(with context: ModelContext) {
        self.modelContext = context
        loadTodaysContract()
        loadUnassignedTasks()
    }

    // MARK: - Contract Management
    func loadTodaysContract() {
        guard let context = modelContext else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyContract>(
            predicate: #Predicate { contract in
                contract.date >= today
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let contracts = try context.fetch(descriptor)
            todaysContract = contracts.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        } catch {
            handleError(error)
        }
    }

    func loadUnassignedTasks() {
        guard let context = modelContext else { return }

        let pendingStatus = TaskStatus.pending
        let descriptor = FetchDescriptor<CoveTask>(
            predicate: #Predicate { task in
                task.contract == nil && task.status == pendingStatus
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            unassignedTasks = try context.fetch(descriptor)
        } catch {
            handleError(error)
        }
    }

    func createTodaysContract() {
        guard let context = modelContext else { return }

        let contract = DailyContract()
        context.insert(contract)
        todaysContract = contract

        do {
            try context.save()
        } catch {
            handleError(error)
        }
    }

    // MARK: - Task Management
    func addTask(_ task: CoveTask, asAnchor: Bool) {
        guard let contract = todaysContract else {
            showErrorMessage("No active contract")
            return
        }

        task.isAnchorTask = asAnchor

        do {
            try contract.addTask(task)
            loadUnassignedTasks()
            try modelContext?.save()
        } catch {
            handleError(error)
        }
    }

    func removeTask(_ task: CoveTask) {
        guard let contract = todaysContract else { return }

        contract.removeTask(task)
        loadUnassignedTasks()

        do {
            try modelContext?.save()
        } catch {
            handleError(error)
        }
    }

    func completeTask(_ task: CoveTask) {
        guard let contract = todaysContract else { return }

        contract.completeTask(task)
        lastCompletedTask = task
        showCompletionCelebration = true

        do {
            try modelContext?.save()
        } catch {
            handleError(error)
        }
    }

    func startTask(_ task: CoveTask) {
        task.status = .inProgress
        task.scheduledFor = Date()

        do {
            try modelContext?.save()
        } catch {
            handleError(error)
        }
    }

    func snoozeTask(_ task: CoveTask) {
        task.snooze()

        do {
            try modelContext?.save()
        } catch {
            handleError(error)
        }
    }

    // MARK: - Computed Properties
    var canAddAnchorTask: Bool {
        todaysContract?.canAddAnchorTask ?? false
    }

    var canAddSideQuest: Bool {
        todaysContract?.canAddSideQuest ?? false
    }

    var progress: Double {
        todaysContract?.progress ?? 0
    }

    var anchorTasksCount: Int {
        todaysContract?.anchorTasks.count ?? 0
    }

    var sideQuestsCount: Int {
        todaysContract?.sideQuests.count ?? 0
    }

    var totalEstimatedMinutes: Int {
        todaysContract?.totalEstimatedMinutes ?? 0
    }

    var isContractComplete: Bool {
        todaysContract?.isComplete ?? false
    }

    var stabilityScore: Double {
        todaysContract?.stabilityScore ?? 0.5
    }

    // MARK: - Time Formatting
    func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    // MARK: - Pessimism Multiplier
    func applyPessimismMultiplier(_ minutes: Int) -> Int {
        Int(Double(minutes) * Constants.defaultPessimismMultiplier)
    }

    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        if let contractError = error as? ContractError {
            showErrorMessage(contractError.errorDescription ?? "Unknown error")
        } else {
            showErrorMessage(error.localizedDescription)
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
