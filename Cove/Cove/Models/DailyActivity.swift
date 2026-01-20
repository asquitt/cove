import Foundation
import SwiftData

@Model
final class DailyActivity {
    var id: UUID
    var date: Date
    var tasksCompleted: Int
    var xpEarned: Int
    var meltdownCount: Int
    var goblinTasksCompleted: Int
    var contractsCompleted: Int

    @Relationship(deleteRule: .nullify, inverse: \UserProfile.dailyActivities)
    var userProfile: UserProfile?

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.tasksCompleted = 0
        self.xpEarned = 0
        self.meltdownCount = 0
        self.goblinTasksCompleted = 0
        self.contractsCompleted = 0
    }

    var activityLevel: ActivityLevel {
        if tasksCompleted == 0 {
            return .none
        } else if tasksCompleted <= 2 {
            return .low
        } else if tasksCompleted <= 4 {
            return .medium
        } else if tasksCompleted <= 6 {
            return .high
        } else {
            return .max
        }
    }

    func recordTaskCompletion(xp: Int) {
        tasksCompleted += 1
        xpEarned += xp
    }

    func recordGoblinTask() {
        goblinTasksCompleted += 1
    }

    func recordMeltdown() {
        meltdownCount += 1
    }

    func recordContractCompletion() {
        contractsCompleted += 1
    }
}

enum ActivityLevel: String, Codable {
    case none
    case low
    case medium
    case high
    case max

    var opacity: Double {
        switch self {
        case .none: return 0.1
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.7
        case .max: return 1.0
        }
    }
}
