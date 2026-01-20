import Foundation
import SwiftData
import Observation

@Observable
final class GamificationService {
    var pendingLevelUp: LevelUpResult?
    var pendingAchievements: [Achievement] = []

    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    func processTaskCompletion(task: CoveTask, profile: UserProfile) -> LevelUpResult? {
        let levelUpResult = profile.recordTaskCompletion(task: task)
        let newAchievements = profile.checkAchievements()

        if let levelUp = levelUpResult {
            pendingLevelUp = levelUp
        }

        if !newAchievements.isEmpty {
            pendingAchievements.append(contentsOf: newAchievements)
        }

        return levelUpResult
    }

    func processGoblinTaskCompletion(profile: UserProfile) {
        profile.recordGoblinTaskCompletion()
        let newAchievements = profile.checkAchievements()

        if !newAchievements.isEmpty {
            pendingAchievements.append(contentsOf: newAchievements)
        }
    }

    func processMeltdownSurvival(profile: UserProfile, goblinTasksCompleted: Int) {
        if goblinTasksCompleted > 0 {
            profile.recordMeltdownSurvival()
            let newAchievements = profile.checkAchievements()

            if !newAchievements.isEmpty {
                pendingAchievements.append(contentsOf: newAchievements)
            }
        }
    }

    func processContractCompletion(profile: UserProfile) {
        profile.recordContractCompletion()
        let newAchievements = profile.checkAchievements()

        if !newAchievements.isEmpty {
            pendingAchievements.append(contentsOf: newAchievements)
        }
    }

    func clearPendingLevelUp() {
        pendingLevelUp = nil
    }

    func popNextAchievement() -> Achievement? {
        guard !pendingAchievements.isEmpty else { return nil }
        return pendingAchievements.removeFirst()
    }

    func hasStreakBonus(profile: UserProfile) -> Bool {
        profile.currentStreak >= 2
    }

    func streakBonusAmount() -> Int {
        Constants.streakBonusXP
    }
}
