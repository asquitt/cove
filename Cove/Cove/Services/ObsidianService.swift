import Foundation
import UIKit
import UniformTypeIdentifiers

/// Service for Obsidian integration
/// Exports tasks and daily notes to Obsidian-compatible markdown format
@Observable
final class ObsidianService {
    // MARK: - Configuration

    /// User's configured Obsidian vault path (stored in UserDefaults)
    var vaultPath: String? {
        get { UserDefaults.standard.string(forKey: "obsidian_vault_path") }
        set { UserDefaults.standard.set(newValue, forKey: "obsidian_vault_path") }
    }

    /// Daily notes folder within the vault
    var dailyNotesFolder: String {
        get { UserDefaults.standard.string(forKey: "obsidian_daily_notes_folder") ?? "Daily Notes" }
        set { UserDefaults.standard.set(newValue, forKey: "obsidian_daily_notes_folder") }
    }

    /// Task notes folder within the vault
    var taskNotesFolder: String {
        get { UserDefaults.standard.string(forKey: "obsidian_task_notes_folder") ?? "Cove Tasks" }
        set { UserDefaults.standard.set(newValue, forKey: "obsidian_task_notes_folder") }
    }

    /// Date format for daily notes filenames
    var dailyNoteDateFormat: String {
        get { UserDefaults.standard.string(forKey: "obsidian_date_format") ?? "yyyy-MM-dd" }
        set { UserDefaults.standard.set(newValue, forKey: "obsidian_date_format") }
    }

    // MARK: - State

    private(set) var isConfigured: Bool = false
    private(set) var lastExportDate: Date?
    private(set) var exportError: ObsidianError?

    // MARK: - Initialization

    init() {
        isConfigured = vaultPath != nil
    }

    // MARK: - Configuration

    /// Check if Obsidian app is installed
    static var isObsidianInstalled: Bool {
        UIApplication.shared.canOpenURL(URL(string: "obsidian://")!)
    }

    /// Configure vault path
    func configure(vaultPath: String) {
        self.vaultPath = vaultPath
        isConfigured = true
    }

    /// Reset configuration
    func disconnect() {
        vaultPath = nil
        isConfigured = false
        lastExportDate = nil
    }

    // MARK: - Export Functions

    /// Generate markdown content for a task
    func generateTaskMarkdown(_ task: CoveTask) -> String {
        var markdown = """
        ---
        title: \(task.title)
        bucket: \(task.bucket.displayName)
        status: \(task.status.displayName)
        interest: \(task.interestLevel.displayName)
        energy: \(task.energyRequired.displayName)
        created: \(formatDate(task.createdAt))
        """

        if let completedAt = task.completedAt {
            markdown += "\ncompleted: \(formatDate(completedAt))"
        }

        if let minutes = task.estimatedMinutes {
            markdown += "\nestimated_minutes: \(minutes)"
        }

        markdown += "\n---\n\n"
        markdown += "# \(task.title)\n\n"

        if let description = task.taskDescription, !description.isEmpty {
            markdown += "## Description\n\n\(description)\n\n"
        }

        markdown += "## Details\n\n"
        markdown += "- **Status:** \(task.status.displayName)\n"
        markdown += "- **Interest:** \(task.interestLevel.emoji) \(task.interestLevel.displayName)\n"
        markdown += "- **Energy:** \(task.energyRequired.emoji) \(task.energyRequired.displayName)\n"

        if let minutes = task.estimatedMinutes {
            markdown += "- **Estimated Time:** \(minutes) minutes\n"
        }

        if task.xpValue > 0 {
            markdown += "- **XP Value:** \(task.xpValue)\n"
        }

        markdown += "\n## Activity Log\n\n"
        markdown += "- Created: \(formatDateTime(task.createdAt))\n"

        if let completedAt = task.completedAt {
            markdown += "- Completed: \(formatDateTime(completedAt))\n"
        }

        if task.snoozeCount > 0 {
            markdown += "- Snoozed: \(task.snoozeCount) time(s)\n"
        }

        return markdown
    }

    /// Generate markdown for a daily contract
    func generateDailyContractMarkdown(_ contract: DailyContract) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let dateString = dateFormatter.string(from: contract.date)

        var markdown = """
        ---
        date: \(formatDate(contract.date))
        stability_score: \(contract.stabilityScore)
        progress: \(Int(contract.progress * 100))%
        tags: [cove, daily-contract]
        ---

        # Daily Contract - \(dateString)

        ## Overview

        - **Progress:** \(Int(contract.progress * 100))%
        - **Stability Score:** \(contract.stabilityScore)
        - **Total Tasks:** \(contract.tasks.count)
        - **Completed:** \(contract.completedTasks.count)

        ## Anchor Tasks

        """

        for task in contract.anchorTasks {
            let checkbox = task.status == .completed ? "[x]" : "[ ]"
            markdown += "- \(checkbox) \(task.title)"
            if let minutes = task.estimatedMinutes {
                markdown += " (\(minutes) min)"
            }
            markdown += "\n"
        }

        if contract.anchorTasks.isEmpty {
            markdown += "_No anchor tasks_\n"
        }

        markdown += "\n## Side Quests\n\n"

        for task in contract.sideQuests {
            let checkbox = task.status == .completed ? "[x]" : "[ ]"
            markdown += "- \(checkbox) \(task.title)"
            if let minutes = task.estimatedMinutes {
                markdown += " (\(minutes) min)"
            }
            markdown += "\n"
        }

        if contract.sideQuests.isEmpty {
            markdown += "_No side quests_\n"
        }

        markdown += "\n## Notes\n\n_Add your reflections here..._\n"

        return markdown
    }

    /// Generate markdown for weekly summary
    func generateWeeklySummaryMarkdown(contracts: [DailyContract], profile: UserProfile) -> String {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        var markdown = """
        ---
        type: weekly-summary
        week_start: \(formatDate(weekStart))
        week_end: \(formatDate(weekEnd))
        tags: [cove, weekly-summary]
        ---

        # Weekly Summary - \(dateFormatter.string(from: weekStart)) to \(dateFormatter.string(from: weekEnd))

        ## Statistics

        - **Tasks Completed:** \(contracts.flatMap { $0.completedTasks }.count)
        - **Current Streak:** \(profile.currentStreak) days
        - **Total XP:** \(profile.totalXPEarned)
        - **Level:** \(profile.currentLevel)

        ## Daily Breakdown

        """

        for contract in contracts.sorted(by: { $0.date < $1.date }) {
            dateFormatter.dateFormat = "EEEE"
            let dayName = dateFormatter.string(from: contract.date)
            let completed = contract.completedTasks.count
            let total = contract.tasks.count
            let progress = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0

            markdown += "### \(dayName)\n"
            markdown += "- Progress: \(progress)%\n"
            markdown += "- Tasks: \(completed)/\(total) completed\n\n"
        }

        markdown += "## Reflections\n\n_Add your weekly reflections here..._\n"

        return markdown
    }

    // MARK: - Export to Files

    /// Export task to a markdown file (returns file data for sharing)
    func exportTaskToFile(_ task: CoveTask) -> (data: Data, filename: String)? {
        let markdown = generateTaskMarkdown(task)
        let sanitizedTitle = sanitizeFilename(task.title)
        let filename = "\(sanitizedTitle).md"

        guard let data = markdown.data(using: .utf8) else { return nil }
        return (data, filename)
    }

    /// Export daily contract to a markdown file
    func exportContractToFile(_ contract: DailyContract) -> (data: Data, filename: String)? {
        let markdown = generateDailyContractMarkdown(contract)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dailyNoteDateFormat
        let filename = "\(dateFormatter.string(from: contract.date)).md"

        guard let data = markdown.data(using: .utf8) else { return nil }
        return (data, filename)
    }

    // MARK: - Obsidian URL Scheme

    /// Open a note in Obsidian (creates if doesn't exist)
    func openInObsidian(filename: String, content: String? = nil) {
        guard let vaultName = vaultPath?.components(separatedBy: "/").last else { return }

        var urlString = "obsidian://new?vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)"
        urlString += "&file=\(filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filename)"

        if let content = content {
            urlString += "&content=\(content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    /// Open daily note in Obsidian
    func openDailyNoteInObsidian(for date: Date = Date()) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dailyNoteDateFormat
        let filename = "\(dailyNotesFolder)/\(dateFormatter.string(from: date))"

        openInObsidian(filename: filename)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private func sanitizeFilename(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - Error Types

enum ObsidianError: LocalizedError {
    case notConfigured
    case vaultNotFound
    case exportFailed
    case invalidFilename

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Please configure your Obsidian vault path in settings."
        case .vaultNotFound:
            return "Could not find the Obsidian vault at the specified path."
        case .exportFailed:
            return "Failed to export to Obsidian."
        case .invalidFilename:
            return "Invalid filename for export."
        }
    }
}
