import Foundation
import SwiftData

@Model
final class CapturedInput {
    var id: UUID
    var rawText: String
    var source: CaptureSource
    var status: CaptureStatus
    var classifiedBucket: TaskBucket?
    var createdAt: Date
    var processedAt: Date?
    var aiResponse: String?

    @Relationship(deleteRule: .nullify)
    var generatedTasks: [CoveTask]

    init(
        rawText: String,
        source: CaptureSource
    ) {
        self.id = UUID()
        self.rawText = rawText
        self.source = source
        self.status = .pending
        self.classifiedBucket = nil
        self.createdAt = Date()
        self.processedAt = nil
        self.aiResponse = nil
        self.generatedTasks = []
    }

    func markProcessed(bucket: TaskBucket, response: String?) {
        status = .processed
        classifiedBucket = bucket
        processedAt = Date()
        aiResponse = response
    }

    func markConfirmed() {
        status = .confirmed
    }

    func markDismissed() {
        status = .dismissed
    }

    var preview: String {
        let maxLength = 100
        if rawText.count <= maxLength {
            return rawText
        }
        return String(rawText.prefix(maxLength)) + "..."
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

enum CaptureSource: String, Codable {
    case voice
    case text
    case quickCapture
    case siri

    var icon: String {
        switch self {
        case .voice: return "mic.fill"
        case .text: return "keyboard"
        case .quickCapture: return "bolt.fill"
        case .siri: return "waveform"
        }
    }

    var displayName: String {
        switch self {
        case .voice: return "Voice"
        case .text: return "Text"
        case .quickCapture: return "Quick"
        case .siri: return "Siri"
        }
    }
}

enum CaptureStatus: String, Codable {
    case pending
    case processing
    case processed
    case confirmed
    case dismissed
    case failed

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing..."
        case .processed: return "Ready for Review"
        case .confirmed: return "Confirmed"
        case .dismissed: return "Dismissed"
        case .failed: return "Failed"
        }
    }
}
