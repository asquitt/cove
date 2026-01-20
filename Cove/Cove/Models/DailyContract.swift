import Foundation
import SwiftData

@Model
final class DailyContract {
    var id: UUID
    var date: Date
    var status: ContractStatus

    @Relationship(deleteRule: .nullify)
    var tasks: [CoveTask]

    var stabilityScore: Double
    var totalEstimatedMinutes: Int
    var totalCompletedMinutes: Int
    var meltdownActivated: Bool
    var meltdownCount: Int
    var createdAt: Date
    var completedAt: Date?

    static let maxAnchorTasks = 3
    static let maxSideQuests = 2

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.status = .draft
        self.tasks = []
        self.stabilityScore = 0.5
        self.totalEstimatedMinutes = 0
        self.totalCompletedMinutes = 0
        self.meltdownActivated = false
        self.meltdownCount = 0
        self.createdAt = Date()
        self.completedAt = nil
    }

    var anchorTasks: [CoveTask] {
        tasks.filter { $0.isAnchorTask }
    }

    var sideQuests: [CoveTask] {
        tasks.filter { !$0.isAnchorTask }
    }

    var completedTasks: [CoveTask] {
        tasks.filter { $0.status == .completed }
    }

    var pendingTasks: [CoveTask] {
        tasks.filter { $0.status == .pending || $0.status == .inProgress }
    }

    var canAddAnchorTask: Bool {
        anchorTasks.count < Self.maxAnchorTasks
    }

    var canAddSideQuest: Bool {
        sideQuests.count < Self.maxSideQuests
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(tasks.count)
    }

    var isComplete: Bool {
        !tasks.isEmpty && pendingTasks.isEmpty
    }

    func addTask(_ task: CoveTask) throws {
        if task.isAnchorTask {
            guard canAddAnchorTask else {
                throw ContractError.anchorTasksFull
            }
        } else {
            guard canAddSideQuest else {
                throw ContractError.sideQuestsFull
            }
        }

        tasks.append(task)
        task.contract = self
        recalculateEstimates()

        if status == .draft {
            status = .active
        }
    }

    func removeTask(_ task: CoveTask) {
        tasks.removeAll { $0.id == task.id }
        task.contract = nil
        recalculateEstimates()
    }

    func completeTask(_ task: CoveTask) {
        task.complete()
        recalculateStability()

        if isComplete {
            status = .completed
            completedAt = Date()
        }
    }

    func activateMeltdown() {
        meltdownActivated = true
        meltdownCount += 1
        stabilityScore = max(0.2, stabilityScore - 0.1)
    }

    func deactivateMeltdown() {
        meltdownActivated = false
    }

    private func recalculateEstimates() {
        totalEstimatedMinutes = tasks.compactMap { $0.estimatedMinutes }.reduce(0, +)
    }

    private func recalculateStability() {
        let completionRatio = progress
        let baseStability = 0.5 + (completionRatio * 0.5)
        let meltdownPenalty = Double(meltdownCount) * 0.05
        stabilityScore = min(1.0, max(0.0, baseStability - meltdownPenalty))
    }
}

enum ContractStatus: String, Codable {
    case draft
    case active
    case completed
    case abandoned

    var displayName: String {
        switch self {
        case .draft: return "Planning"
        case .active: return "In Progress"
        case .completed: return "Complete"
        case .abandoned: return "Abandoned"
        }
    }
}

enum ContractError: LocalizedError {
    case anchorTasksFull
    case sideQuestsFull
    case contractNotActive

    var errorDescription: String? {
        switch self {
        case .anchorTasksFull:
            return "You already have 3 anchor tasks. Remove one to add another."
        case .sideQuestsFull:
            return "You already have 2 side quests. Remove one to add another."
        case .contractNotActive:
            return "Contract is not active."
        }
    }
}
