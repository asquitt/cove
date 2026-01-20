import Foundation
import SwiftData

@Model
final class CoveTask {
    var id: UUID
    var title: String
    var taskDescription: String?
    var bucket: TaskBucket
    var status: TaskStatus
    var estimatedMinutes: Int?
    var actualMinutes: Int?
    var interestLevel: InterestLevel
    var energyRequired: EnergyLevel
    var isAnchorTask: Bool
    var createdAt: Date
    var completedAt: Date?
    var scheduledFor: Date?
    var snoozeCount: Int
    var xpValue: Int

    @Relationship(deleteRule: .nullify, inverse: \DailyContract.tasks)
    var contract: DailyContract?

    init(
        title: String,
        description: String? = nil,
        bucket: TaskBucket = .directive,
        status: TaskStatus = .pending,
        estimatedMinutes: Int? = nil,
        interestLevel: InterestLevel = .medium,
        energyRequired: EnergyLevel = .medium,
        isAnchorTask: Bool = false,
        scheduledFor: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.bucket = bucket
        self.status = status
        self.estimatedMinutes = estimatedMinutes
        self.actualMinutes = nil
        self.interestLevel = interestLevel
        self.energyRequired = energyRequired
        self.isAnchorTask = isAnchorTask
        self.createdAt = Date()
        self.completedAt = nil
        self.scheduledFor = scheduledFor
        self.snoozeCount = 0
        self.xpValue = Self.calculateXP(interest: interestLevel, energy: energyRequired)
    }

    func complete() {
        status = .completed
        completedAt = Date()
        if let scheduled = scheduledFor, estimatedMinutes != nil {
            actualMinutes = Int(Date().timeIntervalSince(scheduled) / 60)
        }
    }

    func snooze() {
        snoozeCount += 1
        status = .snoozed
    }

    private static func calculateXP(interest: InterestLevel, energy: EnergyLevel) -> Int {
        let baseXP = 10
        let interestMultiplier: Double = {
            switch interest {
            case .high: return 1.0
            case .medium: return 1.5
            case .low: return 2.0
            }
        }()
        let energyBonus: Int = {
            switch energy {
            case .high: return 15
            case .medium: return 10
            case .low: return 5
            }
        }()
        return Int(Double(baseXP) * interestMultiplier) + energyBonus
    }
}

enum TaskBucket: String, Codable, CaseIterable {
    case directive
    case archive
    case venting

    var displayName: String {
        switch self {
        case .directive: return "Task"
        case .archive: return "Reference"
        case .venting: return "Processed"
        }
    }

    var icon: String {
        switch self {
        case .directive: return "checkmark.circle"
        case .archive: return "archivebox"
        case .venting: return "heart"
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case inProgress
    case completed
    case snoozed
    case cancelled

    var displayName: String {
        switch self {
        case .pending: return "To Do"
        case .inProgress: return "In Progress"
        case .completed: return "Done"
        case .snoozed: return "Snoozed"
        case .cancelled: return "Cancelled"
        }
    }
}

enum InterestLevel: String, Codable, CaseIterable {
    case high
    case medium
    case low

    var emoji: String {
        switch self {
        case .high: return "🔥"
        case .medium: return "👍"
        case .low: return "😴"
        }
    }

    var displayName: String {
        switch self {
        case .high: return "Exciting"
        case .medium: return "Neutral"
        case .low: return "Boring"
        }
    }
}

enum EnergyLevel: String, Codable, CaseIterable {
    case high
    case medium
    case low

    var emoji: String {
        switch self {
        case .high: return "⚡️"
        case .medium: return "💪"
        case .low: return "🧘"
        }
    }

    var displayName: String {
        switch self {
        case .high: return "High Focus"
        case .medium: return "Moderate"
        case .low: return "Low Effort"
        }
    }
}
