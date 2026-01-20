import Foundation
import SwiftData
import Observation

@Observable
final class PatternService {
    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Pattern Recording

    func recordTaskCompletion(
        task: CoveTask,
        profile: UserProfile,
        userEnergy: EnergyLevel? = nil
    ) {
        let calendar = Calendar.current
        let now = Date()

        let pattern = TaskPattern(
            taskTitle: task.title,
            completionHour: calendar.component(.hour, from: now),
            completionDayOfWeek: calendar.component(.weekday, from: now),
            estimatedMinutes: task.estimatedMinutes ?? 30,
            actualMinutes: task.actualMinutes,
            wasCompleted: true,
            wasSnoozed: task.snoozeCount > 0,
            snoozeCount: task.snoozeCount,
            interestLevel: task.interestLevel,
            energyRequired: task.energyRequired,
            userEnergyAtCompletion: userEnergy
        )

        if profile.taskPatterns == nil {
            profile.taskPatterns = []
        }
        profile.taskPatterns?.append(pattern)
    }

    func recordTaskSnooze(task: CoveTask, profile: UserProfile) {
        // Track snooze patterns without creating full completion record
        // This helps identify tasks that get snoozed frequently
    }

    // MARK: - Pattern Analysis

    func analyzeHourlyProductivity(patterns: [TaskPattern]) -> [HourlyProductivity] {
        var hourData: [Int: (completed: Int, total: Int)] = [:]

        // Initialize all hours
        for hour in 0..<24 {
            hourData[hour] = (0, 0)
        }

        // Count completions by hour
        for pattern in patterns {
            let hour = pattern.completionHour
            var data = hourData[hour] ?? (0, 0)
            data.total += 1
            if pattern.wasCompleted {
                data.completed += 1
            }
            hourData[hour] = data
        }

        // Convert to HourlyProductivity
        return hourData.compactMap { hour, data -> HourlyProductivity? in
            guard data.total >= 3 else { return nil } // Need at least 3 data points
            let rate = data.total > 0 ? Double(data.completed) / Double(data.total) : 0
            return HourlyProductivity(
                hour: hour,
                completionRate: rate,
                taskCount: data.total
            )
        }.sorted { $0.hour < $1.hour }
    }

    func detectPeakHours(patterns: [TaskPattern]) -> [Int] {
        let productivity = analyzeHourlyProductivity(patterns: patterns)
        return productivity
            .filter { $0.completionRate >= 0.7 && $0.taskCount >= 5 }
            .sorted { $0.completionRate > $1.completionRate }
            .prefix(4)
            .map { $0.hour }
    }

    func detectLowHours(patterns: [TaskPattern]) -> [Int] {
        let productivity = analyzeHourlyProductivity(patterns: patterns)
        return productivity
            .filter { $0.completionRate < 0.4 && $0.taskCount >= 3 }
            .sorted { $0.completionRate < $1.completionRate }
            .prefix(4)
            .map { $0.hour }
    }

    func analyzeEnergyRhythm(patterns: [TaskPattern]) -> EnergyRhythm {
        let peakHours = detectPeakHours(patterns: patterns)
        let lowHours = detectLowHours(patterns: patterns)

        let recommendedPattern = determineEnergyPattern(peakHours: peakHours)

        return EnergyRhythm(
            peakHours: peakHours,
            lowHours: lowHours,
            recommendedEnergyPattern: recommendedPattern
        )
    }

    private func determineEnergyPattern(peakHours: [Int]) -> EnergyPattern {
        guard !peakHours.isEmpty else { return .consistent }

        let avgPeakHour = peakHours.reduce(0, +) / peakHours.count

        if avgPeakHour < 10 {
            return .morningPerson
        } else if avgPeakHour >= 10 && avgPeakHour < 14 {
            return .consistent
        } else if avgPeakHour >= 14 && avgPeakHour < 18 {
            return .afternoonPeak
        } else {
            return .nightOwl
        }
    }

    // MARK: - Snooze Pattern Analysis

    func analyzeSnoozePatterns(patterns: [TaskPattern]) -> [SnoozePattern] {
        // Group by task characteristics
        var snoozeCounts: [String: [TaskPattern]] = [:]

        for pattern in patterns {
            // Group by interest level
            let key = "interest_\(pattern.interestLevel.rawValue)"
            if snoozeCounts[key] == nil {
                snoozeCounts[key] = []
            }
            snoozeCounts[key]?.append(pattern)
        }

        return snoozeCounts.compactMap { key, taskPatterns -> SnoozePattern? in
            guard taskPatterns.count >= 5 else { return nil }

            let snoozedTasks = taskPatterns.filter { $0.wasSnoozed }
            let snoozeRate = Double(snoozedTasks.count) / Double(taskPatterns.count)
            let avgSnooze = snoozedTasks.isEmpty ? 0 : Double(snoozedTasks.map { $0.snoozeCount }.reduce(0, +)) / Double(snoozedTasks.count)

            let snoozeHours = snoozedTasks.map { $0.completionHour }
            let commonHours = findCommonElements(snoozeHours)

            return SnoozePattern(
                taskType: key.replacingOccurrences(of: "interest_", with: ""),
                averageSnoozeCount: avgSnooze,
                snoozeRate: snoozeRate,
                commonSnoozeHours: commonHours
            )
        }
    }

    private func findCommonElements(_ array: [Int]) -> [Int] {
        var counts: [Int: Int] = [:]
        for element in array {
            counts[element, default: 0] += 1
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    // MARK: - Estimation Accuracy

    func calculateAverageAccuracy(patterns: [TaskPattern]) -> Double {
        let validPatterns = patterns.compactMap { $0.estimationAccuracy }
        guard !validPatterns.isEmpty else { return 1.0 }
        return validPatterns.reduce(0, +) / Double(validPatterns.count)
    }

    func suggestPessimismMultiplier(patterns: [TaskPattern]) -> Double {
        let avgAccuracy = calculateAverageAccuracy(patterns: patterns)

        // If tasks typically take longer than estimated, increase multiplier
        if avgAccuracy > 1.3 {
            return 2.0
        } else if avgAccuracy > 1.1 {
            return 1.75
        } else if avgAccuracy > 0.9 {
            return 1.5
        } else {
            return 1.25
        }
    }

    // MARK: - Adaptive Suggestions

    func generateSuggestions(
        profile: UserProfile,
        currentHour: Int,
        pendingTasks: [CoveTask]
    ) -> [AdaptiveSuggestion] {
        var suggestions: [AdaptiveSuggestion] = []
        guard let patterns = profile.taskPatterns, patterns.count >= 10 else {
            return suggestions
        }

        let rhythm = analyzeEnergyRhythm(patterns: patterns)
        let snoozePatterns = analyzeSnoozePatterns(patterns: patterns)

        // Peak hour suggestion
        if rhythm.peakHours.contains(currentHour) {
            let highEnergyTasks = pendingTasks.filter { $0.energyRequired == .high }
            if !highEnergyTasks.isEmpty {
                suggestions.append(AdaptiveSuggestion(
                    type: .scheduleTask,
                    message: "You're in your peak hours! Great time for high-focus tasks.",
                    actionLabel: "View Tasks",
                    priority: 1
                ))
            }
        }

        // Low hour suggestion
        if rhythm.lowHours.contains(currentHour) {
            suggestions.append(AdaptiveSuggestion(
                type: .takeBreak,
                message: "Energy typically dips around now. Consider a break or low-effort tasks.",
                actionLabel: nil,
                priority: 2
            ))
        }

        // Snooze warning
        for snoozePattern in snoozePatterns where snoozePattern.isProblematic {
            let affectedTasks = pendingTasks.filter { $0.interestLevel.rawValue == snoozePattern.taskType }
            if !affectedTasks.isEmpty {
                suggestions.append(AdaptiveSuggestion(
                    type: .avoidSnooze,
                    message: "Low-interest tasks often get snoozed. Try tackling them during peak hours.",
                    actionLabel: nil,
                    priority: 3
                ))
                break
            }
        }

        // Estimation adjustment
        let avgAccuracy = calculateAverageAccuracy(patterns: patterns)
        if avgAccuracy > 1.3 {
            suggestions.append(AdaptiveSuggestion(
                type: .adjustEstimate,
                message: "Tasks are taking \(Int((avgAccuracy - 1) * 100))% longer than estimated. Consider increasing your time buffer.",
                actionLabel: "Adjust Settings",
                priority: 4
            ))
        }

        return suggestions.sorted { $0.priority < $1.priority }
    }

    // MARK: - Energy Matching

    func suggestTasksForCurrentEnergy(
        tasks: [CoveTask],
        userEnergy: EnergyLevel,
        currentHour: Int,
        patterns: [TaskPattern]
    ) -> [CoveTask] {
        let rhythm = analyzeEnergyRhythm(patterns: patterns)
        let isPeakHour = rhythm.peakHours.contains(currentHour)

        return tasks.sorted { task1, task2 in
            let score1 = taskEnergyMatchScore(task: task1, userEnergy: userEnergy, isPeakHour: isPeakHour)
            let score2 = taskEnergyMatchScore(task: task2, userEnergy: userEnergy, isPeakHour: isPeakHour)
            return score1 > score2
        }
    }

    private func taskEnergyMatchScore(task: CoveTask, userEnergy: EnergyLevel, isPeakHour: Bool) -> Int {
        var score = 0

        // Match energy levels
        if task.energyRequired == userEnergy {
            score += 3
        } else if (task.energyRequired == .high && userEnergy == .medium) ||
                  (task.energyRequired == .medium && userEnergy == .high) {
            score += 1
        }

        // Bonus for high-interest tasks when energy is low
        if userEnergy == .low && task.interestLevel == .high {
            score += 2
        }

        // Bonus for high-focus tasks during peak hours
        if isPeakHour && task.energyRequired == .high {
            score += 2
        }

        return score
    }
}
