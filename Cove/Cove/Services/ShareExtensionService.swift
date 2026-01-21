import Foundation
import SwiftData

/// Service for handling data shared from the Share Extension
@Observable
final class ShareExtensionService {
    // MARK: - Constants

    private static let appGroupIdentifier = "group.com.cove.app"
    private static let pendingInputsKey = "pendingCapturedInputs"

    // MARK: - State

    private(set) var pendingInputCount: Int = 0
    private(set) var hasPendingInputs: Bool = false

    // MARK: - Initialization

    init() {
        checkForPendingInputs()
    }

    // MARK: - Public Methods

    /// Check if there are pending inputs from the share extension
    func checkForPendingInputs() {
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            pendingInputCount = 0
            hasPendingInputs = false
            return
        }

        let pendingItems = sharedDefaults.array(forKey: Self.pendingInputsKey) as? [[String: Any]] ?? []
        pendingInputCount = pendingItems.count
        hasPendingInputs = pendingInputCount > 0
    }

    /// Fetch all pending inputs from the share extension
    func fetchPendingInputs() -> [SharedInput] {
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            return []
        }

        let pendingItems = sharedDefaults.array(forKey: Self.pendingInputsKey) as? [[String: Any]] ?? []

        return pendingItems.compactMap { item -> SharedInput? in
            guard let id = item["id"] as? String,
                  let text = item["text"] as? String,
                  let timestamp = item["timestamp"] as? TimeInterval else {
                return nil
            }

            let source = item["source"] as? String ?? "unknown"
            return SharedInput(
                id: id,
                text: text,
                timestamp: Date(timeIntervalSince1970: timestamp),
                source: source
            )
        }
    }

    /// Import a shared input as a CapturedInput for processing
    func importAsCapture(_ input: SharedInput, modelContext: ModelContext) -> CapturedInput {
        let capture = CapturedInput(
            rawText: input.text,
            source: .text
        )
        modelContext.insert(capture)
        return capture
    }

    /// Clear a specific pending input after it's been processed
    func clearPendingInput(id: String) {
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            return
        }

        var pendingItems = sharedDefaults.array(forKey: Self.pendingInputsKey) as? [[String: Any]] ?? []
        pendingItems.removeAll { ($0["id"] as? String) == id }
        sharedDefaults.set(pendingItems, forKey: Self.pendingInputsKey)
        sharedDefaults.synchronize()

        checkForPendingInputs()
    }

    /// Clear all pending inputs
    func clearAllPendingInputs() {
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            return
        }

        sharedDefaults.removeObject(forKey: Self.pendingInputsKey)
        sharedDefaults.synchronize()

        pendingInputCount = 0
        hasPendingInputs = false
    }
}

// MARK: - Supporting Types

struct SharedInput: Identifiable {
    let id: String
    let text: String
    let timestamp: Date
    let source: String

    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var sourceDisplayName: String {
        switch source {
        case "share_extension":
            return "Shared"
        case "notes":
            return "Notes"
        case "safari":
            return "Safari"
        default:
            return "External"
        }
    }
}
