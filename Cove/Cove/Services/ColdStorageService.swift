import Foundation
import SwiftData

/// Service for managing Cold Storage (Serendipity Engine)
/// PRD 6.4.3 - Archive ignored goals and periodically suggest revival
@Observable
final class ColdStorageService {
    // MARK: - Configuration

    /// Number of times a task must be ignored before suggesting cold storage
    static let ignoreThreshold = 3

    /// Minimum time in cold storage before revival suggestion (30 days)
    static let minRevivalInterval: TimeInterval = 30 * 24 * 60 * 60

    /// Maximum number of revival suggestions per day
    static let maxDailyRevivalSuggestions = 2

    // MARK: - State

    private(set) var tasksNeedingArchive: [CoveTask] = []
    private(set) var revivalSuggestions: [CoveTask] = []
    private(set) var lastRevivalCheck: Date?

    // MARK: - Cold Storage Analysis

    /// Check for tasks that should be suggested for cold storage
    func analyzeForColdStorage(tasks: [CoveTask]) {
        tasksNeedingArchive = tasks.filter { $0.shouldSuggestColdStorage }
    }

    /// Get all tasks currently in cold storage
    func getColdStorageTasks(from tasks: [CoveTask]) -> [CoveTask] {
        tasks.filter { $0.status == .coldStorage }
            .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }
    }

    // MARK: - Revival System

    /// Check for tasks that could be revived
    func checkForRevivalCandidates(tasks: [CoveTask]) {
        let coldStorageTasks = getColdStorageTasks(from: tasks)

        // Filter to tasks that have been in cold storage long enough
        let candidates = coldStorageTasks.filter { task in
            guard let interval = task.timeSinceArchived else { return false }
            return interval >= Self.minRevivalInterval
        }

        // Randomly select up to max suggestions
        revivalSuggestions = Array(candidates.shuffled().prefix(Self.maxDailyRevivalSuggestions))
        lastRevivalCheck = Date()
    }

    /// Whether we should show revival suggestions (once per day)
    var shouldShowRevivalSuggestions: Bool {
        guard !revivalSuggestions.isEmpty else { return false }
        guard let lastCheck = lastRevivalCheck else { return true }
        return !Calendar.current.isDateInToday(lastCheck)
    }

    // MARK: - Actions

    /// Archive a task to cold storage
    func archiveTask(_ task: CoveTask) {
        task.moveToColdStorage()
        tasksNeedingArchive.removeAll { $0.id == task.id }
    }

    /// Revive a task from cold storage
    func reviveTask(_ task: CoveTask) {
        task.revive()
        revivalSuggestions.removeAll { $0.id == task.id }
    }

    /// Dismiss a revival suggestion (keep in cold storage)
    func dismissRevival(_ task: CoveTask) {
        // Reset the archive date to push back next revival suggestion
        task.archivedAt = Date()
        revivalSuggestions.removeAll { $0.id == task.id }
    }

    /// Permanently delete a task from cold storage
    func deleteFromColdStorage(_ task: CoveTask, context: ModelContext) {
        context.delete(task)
        revivalSuggestions.removeAll { $0.id == task.id }
    }

    // MARK: - Statistics

    /// Get cold storage statistics
    func getStatistics(from tasks: [CoveTask]) -> ColdStorageStats {
        let coldTasks = getColdStorageTasks(from: tasks)
        let totalArchived = coldTasks.count

        let oldestArchived = coldTasks.compactMap { $0.archivedAt }.min()
        let averageAge: TimeInterval? = {
            let ages = coldTasks.compactMap { $0.timeSinceArchived }
            guard !ages.isEmpty else { return nil }
            return ages.reduce(0, +) / Double(ages.count)
        }()

        return ColdStorageStats(
            totalArchived: totalArchived,
            revivalCandidates: revivalSuggestions.count,
            oldestArchivedDate: oldestArchived,
            averageArchiveAge: averageAge
        )
    }
}

// MARK: - Supporting Types

struct ColdStorageStats {
    let totalArchived: Int
    let revivalCandidates: Int
    let oldestArchivedDate: Date?
    let averageArchiveAge: TimeInterval?

    var formattedAverageAge: String? {
        guard let age = averageArchiveAge else { return nil }
        let days = Int(age / (24 * 60 * 60))
        if days == 1 {
            return "1 day"
        } else if days < 30 {
            return "\(days) days"
        } else {
            let months = days / 30
            return months == 1 ? "1 month" : "\(months) months"
        }
    }
}
