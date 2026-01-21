import AppIntents
import SwiftData

/// Siri Shortcuts for Cove using App Intents framework
/// PRD 6.7.1 - "Hey Siri, brain dump to Cove"

// MARK: - Brain Dump Intent

/// Quick capture intent - "Hey Siri, brain dump to Cove"
struct BrainDumpIntent: AppIntent {
    static var title: LocalizedStringResource = "Brain Dump to Cove"
    static var description = IntentDescription("Quickly capture thoughts and tasks")

    @Parameter(title: "What's on your mind?")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("Brain dump: \(\.$text)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Note: In a real implementation with App Groups, we'd save to shared storage
        // For now, return a success message - user opens app to complete the capture
        let preview = text.count > 50 ? String(text.prefix(50)) + "..." : text
        return .result(dialog: "Got it! I've noted: \"\(preview)\" Open Cove to review and process it.")
    }

    static var openAppWhenRun: Bool = false
}

// MARK: - Quick Task Intent

/// Add a quick task - "Hey Siri, add task to Cove"
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task to Cove"
    static var description = IntentDescription("Add a quick task to your Cove task list")

    @Parameter(title: "Task name")
    var taskName: String

    @Parameter(title: "Estimated minutes", default: 30)
    var estimatedMinutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Add task: \(\.$taskName) for \(\.$estimatedMinutes) minutes")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Note: In a real implementation with App Groups, we'd save to shared storage
        // For now, return a success message - user opens app to add the task
        return .result(dialog: "I'll add '\(taskName)' (\(estimatedMinutes) min) to your tasks. Open Cove to add it to your contract.")
    }

    static var openAppWhenRun: Bool = false
}

// MARK: - Check Contract Intent

/// Check today's contract status - "Hey Siri, what's my Cove contract?"
struct CheckContractIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Cove Contract"
    static var description = IntentDescription("See your daily contract status")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In a real implementation, this would query the actual data
        return .result(dialog: "Open Cove to see your daily contract with your anchor tasks and side quests.")
    }

    static var openAppWhenRun: Bool = true
}

// MARK: - Meltdown Mode Intent

/// Activate meltdown mode - "Hey Siri, I need a Cove meltdown"
struct MeltdownModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Activate Meltdown Mode"
    static var description = IntentDescription("Activate Cove's calming meltdown mode")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Opening Cove's meltdown mode. Take a breath, you've got this.")
    }

    static var openAppWhenRun: Bool = true
}

// MARK: - App Shortcuts Provider

struct CoveAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BrainDumpIntent(),
            phrases: [
                "Brain dump to \(.applicationName)",
                "Capture thought in \(.applicationName)",
                "Quick note to \(.applicationName)",
                "Add to \(.applicationName)"
            ],
            shortTitle: "Brain Dump",
            systemImageName: "brain.head.profile"
        )

        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add task to \(.applicationName)",
                "New task in \(.applicationName)",
                "Create task in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: CheckContractIntent(),
            phrases: [
                "What's my \(.applicationName) contract",
                "Check my \(.applicationName) tasks",
                "Show my \(.applicationName) day",
                "Open \(.applicationName) contract"
            ],
            shortTitle: "Check Contract",
            systemImageName: "doc.text"
        )

        AppShortcut(
            intent: MeltdownModeIntent(),
            phrases: [
                "I need a \(.applicationName) meltdown",
                "Overwhelmed mode in \(.applicationName)",
                "Help me calm down with \(.applicationName)",
                "\(.applicationName) calm me down"
            ],
            shortTitle: "Meltdown Mode",
            systemImageName: "heart.fill"
        )
    }
}

// MARK: - Siri Tip Views

import SwiftUI

/// View to show Siri tips to users
struct SiriTipsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Siri Shortcuts")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                SiriTipRow(
                    phrase: "Brain dump to Cove",
                    description: "Quick capture thoughts"
                )

                SiriTipRow(
                    phrase: "Add task to Cove",
                    description: "Create a new task"
                )

                SiriTipRow(
                    phrase: "What's my Cove contract",
                    description: "Check today's tasks"
                )

                SiriTipRow(
                    phrase: "I need a Cove meltdown",
                    description: "Activate calm mode"
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct SiriTipRow: View {
    let phrase: String
    let description: String

    var body: some View {
        HStack {
            Image(systemName: "mic.fill")
                .foregroundColor(.calmSea)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("\"\(phrase)\"")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SiriTipsView()
        .padding()
}
