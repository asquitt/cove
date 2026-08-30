import Foundation

enum FocusBucket: String, Codable, CaseIterable, Hashable {
    case doNext
    case keep
    case release

    var title: String {
        switch self {
        case .doNext: return "Do"
        case .keep: return "Keep"
        case .release: return "Let go"
        }
    }

    var explanation: String {
        switch self {
        case .doNext: return "Turn it into one concrete next step."
        case .keep: return "Save it locally as a reference."
        case .release: return "Acknowledge it, then erase the words."
        }
    }

    var systemImage: String {
        switch self {
        case .doNext: return "arrow.right.circle.fill"
        case .keep: return "tray.full.fill"
        case .release: return "wind"
        }
    }
}

enum PlanRole: String, Codable, CaseIterable, Hashable {
    case anchor
    case sideQuest

    var title: String {
        switch self {
        case .anchor: return "Anchor"
        case .sideQuest: return "Side quest"
        }
    }

    var limit: Int {
        switch self {
        case .anchor: return 3
        case .sideQuest: return 2
        }
    }
}

enum FocusState: String, Codable, Hashable {
    case review
    case confirmed
    case completed
}

enum StudyEventName: String, Codable, CaseIterable, Hashable {
    case studyEnrolled = "study_enrolled"
    case captureSubmitted = "capture_submitted"
    case classificationResolved = "classification_resolved"
    case captureDecided = "capture_decided"
    case taskAssigned = "task_assigned"
    case taskCompleted = "task_completed"
    case weeklyFeedbackSubmitted = "weekly_feedback_submitted"

    var lifecycleOrder: Int {
        switch self {
        case .studyEnrolled: return 0
        case .captureSubmitted: return 10
        case .classificationResolved: return 20
        case .captureDecided: return 30
        case .taskAssigned: return 40
        case .taskCompleted: return 50
        case .weeklyFeedbackSubmitted: return 60
        }
    }
}

enum FrictionReason: String, Codable, CaseIterable, Hashable {
    case none
    case tooManySteps
    case unclearWording
    case dailyPlanTooRigid
    case forgotToReturn
    case other

    var title: String {
        switch self {
        case .none: return "No major friction"
        case .tooManySteps: return "Too many steps"
        case .unclearWording: return "Wording was unclear"
        case .dailyPlanTooRigid: return "The daily plan felt too rigid"
        case .forgotToReturn: return "I forgot to return"
        case .other: return "Something else"
        }
    }
}

struct CohortClassifier {
    private static let releaseSignals = [
        "i feel", "i'm feeling", "im feeling", "overwhelmed", "frustrated",
        "angry", "upset", "vent", "can't deal", "cannot deal"
    ]

    private static let keepSignals = [
        "remember that", "save this", "reference", "idea:", "note:",
        "https://", "http://"
    ]

    static func suggest(for text: String) -> FocusBucket {
        let normalized = text.lowercased()

        if releaseSignals.contains(where: { normalized.contains($0) }) {
            return .release
        }

        if keepSignals.contains(where: { normalized.contains($0) }) {
            return .keep
        }

        return .doNext
    }
}

struct FocusTitle {
    static let maximumLength = 80

    static func make(from text: String) -> String {
        let firstLine = text
            .split(whereSeparator: { $0.isNewline })
            .first
            .map(String.init) ?? text
        let collapsed = firstLine
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard collapsed.count > maximumLength else { return collapsed }
        return String(collapsed.prefix(maximumLength)).trimmingCharacters(in: .whitespaces)
    }
}

struct DayKey {
    static func value(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

struct StudyWeek {
    static let duration: TimeInterval = 7 * 24 * 60 * 60

    static func number(enrolledAt: Date, at date: Date) -> Int {
        let elapsed = max(0, date.timeIntervalSince(enrolledAt))
        return Int(elapsed / duration) + 1
    }
}

struct PlanCounts: Equatable {
    var anchors: Int
    var sideQuests: Int

    func count(for role: PlanRole) -> Int {
        switch role {
        case .anchor: return anchors
        case .sideQuest: return sideQuests
        }
    }

    func canAdd(_ role: PlanRole) -> Bool {
        count(for: role) < role.limit
    }
}

struct StudyMetricsSnapshot: Equatable {
    var activated: Bool
    var retainedWeeks: [Int]
    var retainedAllFourWeeks: Bool
    var statedWillingnessToPay: Bool
    var feedbackWeeks: [Int]
}

struct StudyEventOrdering {
    static func precedes(_ left: StudyEvent, _ right: StudyEvent) -> Bool {
        if left.occurredAt != right.occurredAt {
            return left.occurredAt < right.occurredAt
        }
        if left.lifecycleOrder != right.lifecycleOrder {
            return left.lifecycleOrder < right.lifecycleOrder
        }
        return left.id.uuidString < right.id.uuidString
    }
}

struct StudyMetrics {
    static func snapshot(events: [StudyEvent], checkIns: [WeeklyCheckIn]) -> StudyMetricsSnapshot {
        let groupedEvents = Dictionary(grouping: events.compactMap { event -> (UUID, StudyEvent)? in
            guard let subjectID = event.subjectID else { return nil }
            return (subjectID, event)
        }, by: { $0.0 })
        let validCompletions = groupedEvents.values.flatMap { subjectEvents in
            validCompletionEvents(in: subjectEvents.map { $0.1 })
        }
        let completedWeeks = Set(
            validCompletions
                .compactMap { $0.studyWeek }
                .filter { (1...4).contains($0) }
        )
        let feedbackWeeks = Set(
            checkIns
                .map { $0.studyWeek }
                .filter { (1...4).contains($0) }
        )

        return StudyMetricsSnapshot(
            activated: !validCompletions.isEmpty,
            retainedWeeks: completedWeeks.sorted(),
            retainedAllFourWeeks: Set(1...4).isSubset(of: completedWeeks),
            statedWillingnessToPay: checkIns.contains(where: {
                $0.studyWeek == 4 && $0.willingToPay
            }),
            feedbackWeeks: feedbackWeeks.sorted()
        )
    }

    private static func validCompletionEvents(in events: [StudyEvent]) -> [StudyEvent] {
        var sawCapture = false
        var sawClassification = false
        var sawActionDecision = false
        var assignedRoles = Set<PlanRole>()
        var completions: [StudyEvent] = []

        for event in events.sorted(by: StudyEventOrdering.precedes) {
            switch event.name {
            case .captureSubmitted:
                sawCapture = true
            case .classificationResolved:
                if sawCapture {
                    sawClassification = true
                }
            case .captureDecided:
                if sawCapture, sawClassification, event.outcome == FocusBucket.doNext.rawValue {
                    sawActionDecision = true
                }
            case .taskAssigned:
                if sawActionDecision, let outcome = event.outcome, let role = PlanRole(rawValue: outcome) {
                    assignedRoles.insert(role)
                }
            case .taskCompleted:
                if let outcome = event.outcome,
                   let completedRole = PlanRole(rawValue: outcome),
                   assignedRoles.contains(completedRole) {
                    completions.append(event)
                }
            case .studyEnrolled, .weeklyFeedbackSubmitted:
                break
            }
        }

        return completions
    }
}

struct CohortReport: Codable {
    struct Participant: Codable {
        let id: UUID
        let consentVersion: String
        let studyAgeHours: Int
        let offerPriceCents: Int
        let offerCurrency: String
    }

    struct Event: Codable {
        let id: UUID
        let name: String
        let elapsedHour: Int
        let appBuild: String
        let schemaVersion: Int
        let lifecycleOrder: Int
        let subjectID: UUID?
        let studyWeek: Int?
        let outcome: String?
    }

    struct CheckIn: Codable {
        let studyWeek: Int
        let helpfulness: Int
        let wouldMiss: Int
        let friction: String
        let willingToPay: Bool
        let offerPriceCents: Int
        let offerCurrency: String
    }

    struct Metrics: Codable {
        let activated: Bool
        let retainedWeeks: [Int]
        let retainedAllFourWeeks: Bool
        let statedWillingnessToPay: Bool
        let feedbackWeeks: [Int]
    }

    let protocolID: String
    let schemaVersion: Int
    let participant: Participant
    let events: [Event]
    let checkIns: [CheckIn]
    let metrics: Metrics

    static func make(
        participant: CohortParticipant,
        events: [StudyEvent],
        checkIns: [WeeklyCheckIn],
        generatedAt: Date = Date()
    ) -> CohortReport {
        let participantEvents = events.filter { $0.participantID == participant.id }
        let participantCheckIns = checkIns.filter { $0.participantID == participant.id }
        let snapshot = StudyMetrics.snapshot(events: participantEvents, checkIns: participantCheckIns)
        return CohortReport(
            protocolID: "cove_tf_4w_v1",
            schemaVersion: 1,
            participant: Participant(
                id: participant.id,
                consentVersion: participant.consentVersion,
                studyAgeHours: max(0, Int(generatedAt.timeIntervalSince(participant.enrolledAt) / 3_600)),
                offerPriceCents: participant.offerPriceCents,
                offerCurrency: participant.offerCurrency
            ),
            events: participantEvents
                .sorted(by: StudyEventOrdering.precedes)
                .map {
                    Event(
                        id: $0.id,
                        name: $0.nameRaw,
                        elapsedHour: max(0, Int($0.occurredAt.timeIntervalSince(participant.enrolledAt) / 3_600)),
                        appBuild: $0.appBuild,
                        schemaVersion: $0.schemaVersion,
                        lifecycleOrder: $0.lifecycleOrder,
                        subjectID: $0.subjectID,
                        studyWeek: $0.studyWeek,
                        outcome: $0.outcome
                    )
                },
            checkIns: participantCheckIns
                .sorted { $0.studyWeek < $1.studyWeek }
                .map {
                    CheckIn(
                        studyWeek: $0.studyWeek,
                        helpfulness: $0.helpfulness,
                        wouldMiss: $0.wouldMiss,
                        friction: $0.frictionRaw,
                        willingToPay: $0.willingToPay,
                        offerPriceCents: $0.offerPriceCents,
                        offerCurrency: $0.offerCurrency
                    )
                },
            metrics: Metrics(
                activated: snapshot.activated,
                retainedWeeks: snapshot.retainedWeeks,
                retainedAllFourWeeks: snapshot.retainedAllFourWeeks,
                statedWillingnessToPay: snapshot.statedWillingnessToPay,
                feedbackWeeks: snapshot.feedbackWeeks
            )
        )
    }

    func encodedJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CohortStoreError.reportEncodingFailed
        }
        return string
    }
}
