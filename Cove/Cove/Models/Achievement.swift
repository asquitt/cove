import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var achievementType: AchievementType
    var progress: Int
    var unlockedAt: Date?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \UserProfile.achievements)
    var userProfile: UserProfile?

    init(achievementType: AchievementType) {
        self.id = UUID()
        self.achievementType = achievementType
        self.progress = 0
        self.unlockedAt = nil
        self.createdAt = Date()
    }

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    var progressPercentage: Double {
        Double(progress) / Double(achievementType.requirement)
    }

    func updateProgress(_ newProgress: Int) -> Bool {
        let wasLocked = !isUnlocked
        progress = newProgress

        if wasLocked && progress >= achievementType.requirement {
            unlockedAt = Date()
            return true
        }
        return false
    }
}

enum AchievementType: String, Codable, CaseIterable {
    // Streak achievements
    case firstStreak
    case weekStreak
    case monthStreak

    // Task achievements
    case firstTask
    case tenTasks
    case fiftyTasks
    case hundredTasks

    // Level achievements
    case levelFive
    case levelTen
    case levelTwenty

    // Special achievements
    case meltdownSurvivor
    case goblinMaster

    var displayName: String {
        switch self {
        case .firstStreak: return "Getting Started"
        case .weekStreak: return "Week Warrior"
        case .monthStreak: return "Monthly Master"
        case .firstTask: return "First Step"
        case .tenTasks: return "Getting Momentum"
        case .fiftyTasks: return "Task Tackler"
        case .hundredTasks: return "Centurion"
        case .levelFive: return "Rising Star"
        case .levelTen: return "Skill Builder"
        case .levelTwenty: return "Elite Status"
        case .meltdownSurvivor: return "Resilient"
        case .goblinMaster: return "Goblin Master"
        }
    }

    var description: String {
        switch self {
        case .firstStreak: return "Complete your first 3-day streak"
        case .weekStreak: return "Maintain a 7-day streak"
        case .monthStreak: return "Maintain a 30-day streak"
        case .firstTask: return "Complete your first task"
        case .tenTasks: return "Complete 10 tasks"
        case .fiftyTasks: return "Complete 50 tasks"
        case .hundredTasks: return "Complete 100 tasks"
        case .levelFive: return "Reach level 5"
        case .levelTen: return "Reach level 10"
        case .levelTwenty: return "Reach level 20"
        case .meltdownSurvivor: return "Survive 5 meltdowns"
        case .goblinMaster: return "Complete 20 goblin tasks"
        }
    }

    var icon: String {
        switch self {
        case .firstStreak, .weekStreak, .monthStreak: return "flame.fill"
        case .firstTask, .tenTasks, .fiftyTasks, .hundredTasks: return "checkmark.seal.fill"
        case .levelFive, .levelTen, .levelTwenty: return "star.fill"
        case .meltdownSurvivor: return "heart.fill"
        case .goblinMaster: return "face.smiling.fill"
        }
    }

    var requirement: Int {
        switch self {
        case .firstStreak: return 3
        case .weekStreak: return 7
        case .monthStreak: return 30
        case .firstTask: return 1
        case .tenTasks: return 10
        case .fiftyTasks: return 50
        case .hundredTasks: return 100
        case .levelFive: return 5
        case .levelTen: return 10
        case .levelTwenty: return 20
        case .meltdownSurvivor: return 5
        case .goblinMaster: return 20
        }
    }

    var xpReward: Int {
        switch self {
        case .firstStreak: return 25
        case .weekStreak: return 50
        case .monthStreak: return 150
        case .firstTask: return 10
        case .tenTasks: return 50
        case .fiftyTasks: return 100
        case .hundredTasks: return 250
        case .levelFive: return 50
        case .levelTen: return 100
        case .levelTwenty: return 250
        case .meltdownSurvivor: return 75
        case .goblinMaster: return 100
        }
    }
}
