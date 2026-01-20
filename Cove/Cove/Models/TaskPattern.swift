import Foundation
import SwiftData

@Model
final class TaskPattern {
    var id: UUID
    var taskTitle: String
    var completionHour: Int
    var completionDayOfWeek: Int
    var estimatedMinutes: Int
    var actualMinutes: Int?
    var wasCompleted: Bool
    var wasSnoozed: Bool
    var snoozeCount: Int
    var interestLevel: InterestLevel
    var energyRequired: EnergyLevel
    var userEnergyAtCompletion: EnergyLevel?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \UserProfile.taskPatterns)
    var userProfile: UserProfile?

    init(
        taskTitle: String,
        completionHour: Int,
        completionDayOfWeek: Int,
        estimatedMinutes: Int,
        actualMinutes: Int? = nil,
        wasCompleted: Bool,
        wasSnoozed: Bool = false,
        snoozeCount: Int = 0,
        interestLevel: InterestLevel,
        energyRequired: EnergyLevel,
        userEnergyAtCompletion: EnergyLevel? = nil
    ) {
        self.id = UUID()
        self.taskTitle = taskTitle
        self.completionHour = completionHour
        self.completionDayOfWeek = completionDayOfWeek
        self.estimatedMinutes = estimatedMinutes
        self.actualMinutes = actualMinutes
        self.wasCompleted = wasCompleted
        self.wasSnoozed = wasSnoozed
        self.snoozeCount = snoozeCount
        self.interestLevel = interestLevel
        self.energyRequired = energyRequired
        self.userEnergyAtCompletion = userEnergyAtCompletion
        self.createdAt = Date()
    }

    var estimationAccuracy: Double? {
        guard let actual = actualMinutes, estimatedMinutes > 0 else { return nil }
        return Double(actual) / Double(estimatedMinutes)
    }

    var wasUnderestimated: Bool {
        guard let accuracy = estimationAccuracy else { return false }
        return accuracy > 1.2
    }

    var wasOverestimated: Bool {
        guard let accuracy = estimationAccuracy else { return false }
        return accuracy < 0.8
    }
}

struct HourlyProductivity: Identifiable {
    let id = UUID()
    let hour: Int
    let completionRate: Double
    let taskCount: Int

    var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }

    var productivityLevel: ProductivityLevel {
        if completionRate >= 0.8 { return .peak }
        if completionRate >= 0.6 { return .good }
        if completionRate >= 0.4 { return .moderate }
        return .low
    }
}

enum ProductivityLevel: String {
    case peak
    case good
    case moderate
    case low

    var displayName: String {
        switch self {
        case .peak: return "Peak"
        case .good: return "Good"
        case .moderate: return "Moderate"
        case .low: return "Low"
        }
    }

    var color: String {
        switch self {
        case .peak: return "zenGreen"
        case .good: return "softWave"
        case .moderate: return "warmSand"
        case .low: return "coralAlert"
        }
    }
}

struct SnoozePattern: Identifiable {
    let id = UUID()
    let taskType: String
    let averageSnoozeCount: Double
    let snoozeRate: Double
    let commonSnoozeHours: [Int]

    var isProblematic: Bool {
        snoozeRate > 0.5 || averageSnoozeCount > 2
    }
}

struct EnergyRhythm: Identifiable {
    let id = UUID()
    let peakHours: [Int]
    let lowHours: [Int]
    let recommendedEnergyPattern: EnergyPattern

    var peakHoursDescription: String {
        guard !peakHours.isEmpty else { return "Not enough data" }
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let labels = peakHours.prefix(3).map { hour -> String in
            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            return formatter.string(from: date).lowercased()
        }
        return labels.joined(separator: ", ")
    }
}

struct AdaptiveSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let message: String
    let actionLabel: String?
    let priority: Int

    enum SuggestionType {
        case scheduleTask
        case avoidSnooze
        case energyMatch
        case adjustEstimate
        case takeBreak
    }
}
