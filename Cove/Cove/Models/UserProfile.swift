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
    }

    func adjustedEstimate(minutes: Int) -> Int {
        Int(Double(minutes) * pessimismMultiplier)
    }

    func recordTaskCompletion(xp: Int) {
        totalTasksCompleted += 1
        totalXPEarned += xp
        updateStreak()
    }

    func recordMeltdown() {
        // Meltdowns don't break streaks - surviving is success
    }

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

    var currentLevel: Int {
        let xpPerLevel = 100
        return (totalXPEarned / xpPerLevel) + 1
    }

    var xpToNextLevel: Int {
        let xpPerLevel = 100
        return xpPerLevel - (totalXPEarned % xpPerLevel)
    }

    var levelProgress: Double {
        let xpPerLevel = 100
        return Double(totalXPEarned % xpPerLevel) / Double(xpPerLevel)
    }
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
