import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var pessimismMultiplier: Double
    var preferredWorkStartHour: Int
    var preferredWorkEndHour: Int
    var energyPattern: EnergyPattern
    var hasCompletedOnboarding: Bool
    var claudeAPIKey: String?
    var createdAt: Date
    var totalTasksCompleted: Int
    var totalXPEarned: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var totalGoblinTasksCompleted: Int
    var totalMeltdownsSurvived: Int
    var totalContractsCompleted: Int

    @Relationship(deleteRule: .cascade)
    var skillCategories: [SkillCategory]?

    @Relationship(deleteRule: .cascade)
    var dailyActivities: [DailyActivity]?

    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement]?

    @Relationship(deleteRule: .cascade)
    var taskPatterns: [TaskPattern]?

    init(displayName: String = "Friend") {
        self.id = UUID()
        self.displayName = displayName
        self.pessimismMultiplier = 1.5
        self.preferredWorkStartHour = 9
        self.preferredWorkEndHour = 17
        self.energyPattern = .morningPerson
        self.hasCompletedOnboarding = false
        self.claudeAPIKey = nil
        self.createdAt = Date()
        self.totalTasksCompleted = 0
        self.totalXPEarned = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = nil
        self.totalGoblinTasksCompleted = 0
        self.totalMeltdownsSurvived = 0
        self.totalContractsCompleted = 0
        self.skillCategories = []
        self.dailyActivities = []
        self.achievements = []
        self.taskPatterns = []
    }

    func adjustedEstimate(minutes: Int) -> Int {
        Int(Double(minutes) * pessimismMultiplier)
    }

    // MARK: - Gamification Methods

    func recordTaskCompletion(task: CoveTask) -> LevelUpResult? {
        let xp = task.xpValue
        let oldLevel = currentLevel

        totalTasksCompleted += 1
        totalXPEarned += xp
        updateStreak()

        // Add streak bonus
        if currentStreak >= 2 {
            totalXPEarned += Constants.streakBonusXP
        }

        // Update daily activity
        updateDailyActivity { activity in
            activity.recordTaskCompletion(xp: xp)
        }

        // Award skill XP based on task attributes
        awardSkillXP(for: task)

        let newLevel = currentLevel

        if newLevel > oldLevel {
            return LevelUpResult(oldLevel: oldLevel, newLevel: newLevel, xpEarned: xp)
        }
        return nil
    }

    func recordTaskCompletion(xp: Int) {
        totalTasksCompleted += 1
        totalXPEarned += xp
        updateStreak()
    }

    func recordGoblinTaskCompletion() {
        let xp = 5
        totalGoblinTasksCompleted += 1
        totalXPEarned += xp

        // Award emotional regulation skill XP
        if let skills = skillCategories {
            if let emotionalSkill = skills.first(where: { $0.skillType == .emotionalRegulation }) {
                emotionalSkill.addXP(10)
            }
        }

        updateDailyActivity { activity in
            activity.recordGoblinTask()
            activity.xpEarned += xp
        }
    }

    func recordMeltdownSurvival() {
        let xp = Constants.meltdownSurvivalXP
        totalMeltdownsSurvived += 1
        totalXPEarned += xp

        // Award emotional regulation skill XP
        if let skills = skillCategories {
            if let emotionalSkill = skills.first(where: { $0.skillType == .emotionalRegulation }) {
                emotionalSkill.addXP(15)
            }
        }

        updateDailyActivity { activity in
            activity.recordMeltdown()
            activity.xpEarned += xp
        }
    }

    func recordMeltdown() {
        // Meltdowns don't break streaks - surviving is success
    }

    func recordContractCompletion() {
        totalContractsCompleted += 1

        updateDailyActivity { activity in
            activity.recordContractCompletion()
        }
    }

    func checkAchievements() -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        guard let achievements = achievements else { return [] }

        for achievement in achievements {
            let newProgress: Int
            switch achievement.achievementType {
            case .firstStreak, .weekStreak, .monthStreak:
                newProgress = currentStreak
            case .firstTask, .tenTasks, .fiftyTasks, .hundredTasks:
                newProgress = totalTasksCompleted
            case .levelFive, .levelTen, .levelTwenty:
                newProgress = currentLevel
            case .meltdownSurvivor:
                newProgress = totalMeltdownsSurvived
            case .goblinMaster:
                newProgress = totalGoblinTasksCompleted
            }

            if achievement.updateProgress(newProgress) {
                totalXPEarned += achievement.achievementType.xpReward
                newlyUnlocked.append(achievement)
            }
        }

        return newlyUnlocked
    }

    func initializeGamification() {
        // Initialize skill categories if empty
        if skillCategories?.isEmpty ?? true {
            skillCategories = SkillType.allCases.map { SkillCategory(skillType: $0) }
        }

        // Initialize achievements if empty
        if achievements?.isEmpty ?? true {
            achievements = AchievementType.allCases.map { Achievement(achievementType: $0) }
        }
    }

    // MARK: - Private Methods

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActive = lastActiveDate {
            let lastActiveDay = calendar.startOfDay(for: lastActive)
            let daysBetween = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

            if daysBetween == 1 {
                currentStreak += 1
            } else if daysBetween > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastActiveDate = Date()
    }

    private func awardSkillXP(for task: CoveTask) {
        guard let skills = skillCategories else { return }

        // Focus skill - based on energy required
        if let focusSkill = skills.first(where: { $0.skillType == .focus }) {
            let xp: Int
            switch task.energyRequired {
            case .high: xp = 15
            case .medium: xp = 10
            case .low: xp = 5
            }
            focusSkill.addXP(xp)
        }

        // Energy management skill - based on matching task to energy
        if let energySkill = skills.first(where: { $0.skillType == .energyManagement }) {
            energySkill.addXP(10)
        }

        // Consistency skill - always gains XP on completion
        if let consistencySkill = skills.first(where: { $0.skillType == .consistency }) {
            consistencySkill.addXP(5 + (currentStreak > 0 ? 5 : 0))
        }
    }

    private func updateDailyActivity(_ update: (DailyActivity) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())

        if let activities = dailyActivities,
           let todayActivity = activities.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            update(todayActivity)
        } else {
            let newActivity = DailyActivity(date: today)
            update(newActivity)
            if dailyActivities == nil {
                dailyActivities = []
            }
            dailyActivities?.append(newActivity)
        }
    }

    var currentLevel: Int {
        let xpPerLevel = Constants.xpPerLevel
        return (totalXPEarned / xpPerLevel) + 1
    }

    var xpToNextLevel: Int {
        let xpPerLevel = Constants.xpPerLevel
        return xpPerLevel - (totalXPEarned % xpPerLevel)
    }

    var levelProgress: Double {
        let xpPerLevel = Constants.xpPerLevel
        return Double(totalXPEarned % xpPerLevel) / Double(xpPerLevel)
    }
}

struct LevelUpResult {
    let oldLevel: Int
    let newLevel: Int
    let xpEarned: Int
}

enum EnergyPattern: String, Codable, CaseIterable {
    case morningPerson
    case nightOwl
    case afternoonPeak
    case consistent

    var displayName: String {
        switch self {
        case .morningPerson: return "Morning Person"
        case .nightOwl: return "Night Owl"
        case .afternoonPeak: return "Afternoon Peak"
        case .consistent: return "Consistent"
        }
    }

    var description: String {
        switch self {
        case .morningPerson: return "Most productive in early morning"
        case .nightOwl: return "Most productive late at night"
        case .afternoonPeak: return "Most productive after lunch"
        case .consistent: return "Steady energy throughout the day"
        }
    }

    var peakHours: ClosedRange<Int> {
        switch self {
        case .morningPerson: return 6...10
        case .nightOwl: return 20...24
        case .afternoonPeak: return 13...17
        case .consistent: return 9...17
        }
    }
}
