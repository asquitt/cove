import Foundation
import HealthKit

/// Service for reading Apple Health data for energy modeling
/// PRD 6.7.1 - Apple Health integration (read sleep/activity for energy)
@Observable
final class HealthService {
    // MARK: - State
    private let healthStore = HKHealthStore()
    private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined
    private(set) var isLoading = false
    var error: HealthError?

    // MARK: - Health Data
    private(set) var lastNightSleep: SleepData?
    private(set) var todayActivity: ActivityData?
    private(set) var energyEstimate: EnergyEstimate?

    // MARK: - Initialization
    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Availability Check
    static var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization
    func requestAccess() async -> Bool {
        guard Self.isHealthDataAvailable else {
            error = .notAvailable
            return false
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run {
                checkAuthorizationStatus()
            }
            return true
        } catch {
            await MainActor.run {
                self.error = .authorizationFailed(error.localizedDescription)
            }
            return false
        }
    }

    private func checkAuthorizationStatus() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        authorizationStatus = healthStore.authorizationStatus(for: sleepType)
    }

    var hasHealthAccess: Bool {
        authorizationStatus == .sharingAuthorized
    }

    var needsPermission: Bool {
        authorizationStatus == .notDetermined
    }

    // MARK: - Fetch Sleep Data
    func fetchLastNightSleep() async -> SleepData? {
        guard Self.isHealthDataAvailable else { return nil }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        // Get sleep from yesterday evening to this morning
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let yesterdayEvening = calendar.date(byAdding: .hour, value: -12, to: startOfToday)!

        let predicate = HKQuery.predicateForSamples(
            withStart: yesterdayEvening,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard error == nil, let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Calculate total sleep time
                var totalSleepSeconds: TimeInterval = 0
                var deepSleepSeconds: TimeInterval = 0
                var remSleepSeconds: TimeInterval = 0

                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)

                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepSleepSeconds += duration
                        totalSleepSeconds += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remSleepSeconds += duration
                        totalSleepSeconds += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        totalSleepSeconds += duration
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        totalSleepSeconds += duration
                    default:
                        break
                    }
                }

                let sleepData = SleepData(
                    totalHours: totalSleepSeconds / 3600,
                    deepSleepHours: deepSleepSeconds / 3600,
                    remSleepHours: remSleepSeconds / 3600,
                    date: startOfToday
                )

                continuation.resume(returning: sleepData)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Activity Data
    func fetchTodayActivity() async -> ActivityData? {
        guard Self.isHealthDataAvailable else { return nil }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let now = Date()

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        async let steps = fetchSum(for: stepType, predicate: predicate, unit: .count())
        async let energy = fetchSum(for: energyType, predicate: predicate, unit: .kilocalorie())

        let (stepCount, activeEnergy) = await (steps, energy)

        return ActivityData(
            steps: Int(stepCount ?? 0),
            activeCalories: Int(activeEnergy ?? 0),
            date: startOfDay
        )
    }

    private func fetchSum(for type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Energy Estimation
    func calculateEnergyEstimate() async -> EnergyEstimate {
        isLoading = true
        defer { isLoading = false }

        // Fetch data concurrently
        async let sleepTask = fetchLastNightSleep()
        async let activityTask = fetchTodayActivity()

        let (sleep, activity) = await (sleepTask, activityTask)

        lastNightSleep = sleep
        todayActivity = activity

        // Calculate energy score
        var energyScore: Double = 50 // Baseline

        // Sleep impact (major factor)
        if let sleep = sleep {
            if sleep.totalHours >= 7 {
                energyScore += 25
            } else if sleep.totalHours >= 6 {
                energyScore += 15
            } else if sleep.totalHours >= 5 {
                energyScore += 5
            } else {
                energyScore -= 15 // Poor sleep reduces energy
            }

            // Deep sleep bonus
            if sleep.deepSleepHours >= 1.5 {
                energyScore += 10
            }
        }

        // Activity impact
        if let activity = activity {
            if activity.steps >= 5000 {
                energyScore += 10 // Active, but not exhausted
            } else if activity.steps >= 10000 {
                energyScore += 5 // Very active, might be tired
            }
        }

        // Time of day adjustment
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 9...11: energyScore += 10 // Morning peak
        case 14...16: energyScore -= 10 // Afternoon slump
        case 20...23: energyScore -= 15 // Evening wind-down
        default: break
        }

        // Clamp to valid range
        energyScore = max(0, min(100, energyScore))

        let estimate = EnergyEstimate(
            score: Int(energyScore),
            level: EnergyLevel(fromScore: energyScore),
            factors: buildFactors(sleep: sleep, activity: activity),
            timestamp: Date()
        )

        energyEstimate = estimate
        return estimate
    }

    private func buildFactors(sleep: SleepData?, activity: ActivityData?) -> [EnergyFactor] {
        var factors: [EnergyFactor] = []

        if let sleep = sleep {
            if sleep.totalHours < 6 {
                factors.append(EnergyFactor(
                    type: .sleep,
                    impact: .negative,
                    description: "Only \(String(format: "%.1f", sleep.totalHours))h sleep last night"
                ))
            } else if sleep.totalHours >= 7 {
                factors.append(EnergyFactor(
                    type: .sleep,
                    impact: .positive,
                    description: "\(String(format: "%.1f", sleep.totalHours))h of quality sleep"
                ))
            }
        } else {
            factors.append(EnergyFactor(
                type: .sleep,
                impact: .neutral,
                description: "Sleep data unavailable"
            ))
        }

        if let activity = activity {
            if activity.steps >= 5000 {
                factors.append(EnergyFactor(
                    type: .activity,
                    impact: .positive,
                    description: "\(activity.steps.formatted()) steps today"
                ))
            }
        }

        // Time of day
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 14 && hour <= 16 {
            factors.append(EnergyFactor(
                type: .timeOfDay,
                impact: .negative,
                description: "Afternoon energy dip is normal"
            ))
        } else if hour >= 9 && hour <= 11 {
            factors.append(EnergyFactor(
                type: .timeOfDay,
                impact: .positive,
                description: "Morning peak energy time"
            ))
        }

        return factors
    }

    // MARK: - Suggestions
    func getTaskSuggestions(for tasks: [CoveTask]) -> [CoveTask] {
        guard let estimate = energyEstimate else { return tasks }

        // Sort tasks by energy match
        return tasks.sorted { task1, task2 in
            let match1 = energyMatch(task: task1, energy: estimate.level)
            let match2 = energyMatch(task: task2, energy: estimate.level)
            return match1 > match2
        }
    }

    private func energyMatch(task: CoveTask, energy: EnergyLevel) -> Int {
        switch (task.energyRequired, energy) {
        case (.high, .high): return 3
        case (.high, .medium): return 1
        case (.high, .low): return 0
        case (.medium, .medium): return 3
        case (.medium, .high), (.medium, .low): return 2
        case (.low, .low): return 3
        case (.low, .medium): return 2
        case (.low, .high): return 1
        }
    }
}

// MARK: - Data Models

struct SleepData {
    let totalHours: Double
    let deepSleepHours: Double
    let remSleepHours: Double
    let date: Date

    var quality: SleepQuality {
        if totalHours >= 7 && deepSleepHours >= 1 {
            return .good
        } else if totalHours >= 6 {
            return .fair
        } else {
            return .poor
        }
    }
}

enum SleepQuality: String {
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var color: String {
        switch self {
        case .good: return "zenGreen"
        case .fair: return "warmSand"
        case .poor: return "coralAlert"
        }
    }
}

struct ActivityData {
    let steps: Int
    let activeCalories: Int
    let date: Date
}

struct EnergyEstimate {
    let score: Int // 0-100
    let level: EnergyLevel
    let factors: [EnergyFactor]
    let timestamp: Date

    var recommendation: String {
        switch level {
        case .high:
            return "Great energy! Tackle your challenging tasks now."
        case .medium:
            return "Moderate energy. Mix of tasks should work well."
        case .low:
            return "Lower energy. Focus on easier tasks or take a break."
        }
    }
}

struct EnergyFactor {
    let type: FactorType
    let impact: Impact
    let description: String

    enum FactorType {
        case sleep
        case activity
        case timeOfDay
        case weather
    }

    enum Impact {
        case positive
        case neutral
        case negative
    }
}

extension EnergyLevel {
    init(fromScore score: Double) {
        if score >= 70 {
            self = .high
        } else if score >= 40 {
            self = .medium
        } else {
            self = .low
        }
    }
}

// MARK: - Errors

enum HealthError: LocalizedError {
    case notAvailable
    case authorizationFailed(String)
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Apple Health is not available on this device."
        case .authorizationFailed(let reason):
            return "Health access denied: \(reason)"
        case .fetchFailed(let reason):
            return "Failed to fetch health data: \(reason)"
        }
    }
}
