import Foundation
import SwiftData

enum CohortStoreError: LocalizedError, Equatable {
    case emptyCapture
    case captureTooLong
    case emptyTitle
    case invalidEstimate
    case invalidState
    case planFull(PlanRole)
    case feedbackWeekUnavailable
    case persistenceFailed
    case reportEncodingFailed

    var errorDescription: String? {
        switch self {
        case .emptyCapture:
            return "Write one thought before sorting it."
        case .captureTooLong:
            return "Keep this capture under 500 characters."
        case .emptyTitle:
            return "Give this next step a short title."
        case .invalidEstimate:
            return "Choose an estimate between 5 and 120 minutes."
        case .invalidState:
            return "That item has already moved past this step."
        case .planFull(let role):
            return "Today's \(role.title.lowercased()) slots are full."
        case .feedbackWeekUnavailable:
            return "Weekly check-ins are available during study weeks 1 through 4."
        case .persistenceFailed:
            return "Cove could not save that change. Nothing was reported as complete."
        case .reportEncodingFailed:
            return "Cove could not prepare the local study report."
        }
    }
}

@MainActor
enum CohortStore {
    static let consentVersion = "cove-study-v1"
    static let maximumCaptureLength = 500

    static func enroll(
        in context: ModelContext,
        at date: Date = Date(),
        participantID: UUID = UUID()
    ) throws -> CohortParticipant {
        let participant = CohortParticipant(
            id: participantID,
            consentVersion: consentVersion,
            enrolledAt: date
        )
        context.insert(participant)
        context.insert(
            makeEvent(
                participant: participant,
                name: .studyEnrolled,
                at: date,
                outcome: consentVersion
            )
        )
        try save(context)
        return participant
    }

    static func capture(
        _ text: String,
        participant: CohortParticipant,
        in context: ModelContext,
        at date: Date = Date()
    ) throws -> FocusItem {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { throw CohortStoreError.emptyCapture }
        guard normalized.count <= maximumCaptureLength else { throw CohortStoreError.captureTooLong }

        let suggestion = CohortClassifier.suggest(for: normalized)
        let item = FocusItem(
            rawText: normalized,
            title: FocusTitle.make(from: normalized),
            suggestedBucket: suggestion,
            createdAt: date
        )
        let week = StudyWeek.number(enrolledAt: participant.enrolledAt, at: date)

        context.insert(item)
        context.insert(
            makeEvent(
                participant: participant,
                name: .captureSubmitted,
                at: date,
                subjectID: item.id,
                studyWeek: week,
                outcome: "text_local"
            )
        )
        context.insert(
            makeEvent(
                participant: participant,
                name: .classificationResolved,
                at: date,
                subjectID: item.id,
                studyWeek: week,
                outcome: suggestion.rawValue
            )
        )
        try save(context)
        return item
    }

    static func confirm(
        _ item: FocusItem,
        bucket: FocusBucket,
        title: String,
        estimateMinutes: Int,
        role: PlanRole?,
        participant: CohortParticipant,
        in context: ModelContext,
        at date: Date = Date(),
        calendar: Calendar = .current
    ) throws {
        guard item.state == .review else { throw CohortStoreError.invalidState }

        let normalizedTitle = FocusTitle.make(from: title)
        let week = StudyWeek.number(enrolledAt: participant.enrolledAt, at: date)

        if bucket == .doNext {
            guard !normalizedTitle.isEmpty else { throw CohortStoreError.emptyTitle }
            guard (5...120).contains(estimateMinutes) else { throw CohortStoreError.invalidEstimate }
            item.title = normalizedTitle
            item.estimatedMinutes = estimateMinutes

            if let role = role {
                let dayKey = DayKey.value(for: date, calendar: calendar)
                let counts = try planCounts(dayKey: dayKey, in: context)
                guard counts.canAdd(role) else { throw CohortStoreError.planFull(role) }

                item.role = role
                item.planDayKey = dayKey
                context.insert(
                    makeEvent(
                        participant: participant,
                        name: .taskAssigned,
                        at: date,
                        subjectID: item.id,
                        studyWeek: week,
                        outcome: role.rawValue
                    )
                )
            } else {
                item.role = nil
                item.planDayKey = nil
            }
        } else {
            item.role = nil
            item.planDayKey = nil
            if bucket == .release {
                item.rawText = ""
                item.title = ""
            }
        }

        item.bucket = bucket
        item.state = .confirmed
        item.confirmedAt = date
        context.insert(
            makeEvent(
                participant: participant,
                name: .captureDecided,
                at: date,
                subjectID: item.id,
                studyWeek: week,
                outcome: bucket.rawValue
            )
        )
        try save(context)
    }

    @discardableResult
    static func assignToToday(
        _ item: FocusItem,
        role: PlanRole,
        participant: CohortParticipant,
        in context: ModelContext,
        at date: Date = Date(),
        calendar: Calendar = .current
    ) throws -> Bool {
        guard item.bucket == .doNext, item.state == .confirmed else {
            throw CohortStoreError.invalidState
        }

        let dayKey = DayKey.value(for: date, calendar: calendar)
        if item.planDayKey == dayKey, item.role == role {
            return false
        }

        let counts = try planCounts(dayKey: dayKey, in: context)
        guard counts.canAdd(role) else { throw CohortStoreError.planFull(role) }

        item.role = role
        item.planDayKey = dayKey
        context.insert(
            makeEvent(
                participant: participant,
                name: .taskAssigned,
                at: date,
                subjectID: item.id,
                studyWeek: StudyWeek.number(enrolledAt: participant.enrolledAt, at: date),
                outcome: role.rawValue
            )
        )
        try save(context)
        return true
    }

    @discardableResult
    static func complete(
        _ item: FocusItem,
        participant: CohortParticipant,
        in context: ModelContext,
        at date: Date = Date()
    ) throws -> Bool {
        guard item.bucket == .doNext, item.planDayKey != nil else {
            throw CohortStoreError.invalidState
        }
        if item.state == .completed {
            return false
        }
        guard item.state == .confirmed else { throw CohortStoreError.invalidState }

        item.state = .completed
        item.completedAt = date
        context.insert(
            makeEvent(
                participant: participant,
                name: .taskCompleted,
                at: date,
                subjectID: item.id,
                studyWeek: StudyWeek.number(enrolledAt: participant.enrolledAt, at: date),
                outcome: item.roleRaw
            )
        )
        try save(context)
        return true
    }

    static func submitCheckIn(
        participant: CohortParticipant,
        helpfulness: Int,
        wouldMiss: Int,
        friction: FrictionReason,
        willingToPay: Bool,
        in context: ModelContext,
        at date: Date = Date()
    ) throws -> WeeklyCheckIn {
        let week = StudyWeek.number(enrolledAt: participant.enrolledAt, at: date)
        guard (1...4).contains(week) else { throw CohortStoreError.feedbackWeekUnavailable }

        if let existing = try context.fetch(FetchDescriptor<WeeklyCheckIn>()).first(where: {
            $0.participantID == participant.id && $0.studyWeek == week
        }) {
            return existing
        }

        let normalizedWillingness = week == 4 && willingToPay
        let checkIn = WeeklyCheckIn(
            participantID: participant.id,
            studyWeek: week,
            submittedAt: date,
            helpfulness: min(5, max(1, helpfulness)),
            wouldMiss: min(5, max(1, wouldMiss)),
            friction: friction,
            willingToPay: normalizedWillingness,
            offerPriceCents: participant.offerPriceCents,
            offerCurrency: participant.offerCurrency
        )
        context.insert(checkIn)
        context.insert(
            makeEvent(
                participant: participant,
                name: .weeklyFeedbackSubmitted,
                at: date,
                studyWeek: week,
                outcome: week == 4
                    ? (normalizedWillingness ? "stated_yes" : "stated_no")
                    : "feedback_recorded"
            )
        )

        try save(context)
        return checkIn
    }

    static func planCounts(dayKey: String, in context: ModelContext) throws -> PlanCounts {
        let items = try context.fetch(FetchDescriptor<FocusItem>())
            .filter { $0.planDayKey == dayKey && $0.bucket == .doNext }
        return PlanCounts(
            anchors: items.filter { $0.role == .anchor }.count,
            sideQuests: items.filter { $0.role == .sideQuest }.count
        )
    }

    static func deleteAllData(in context: ModelContext) throws {
        for event in try context.fetch(FetchDescriptor<StudyEvent>()) {
            context.delete(event)
        }
        for checkIn in try context.fetch(FetchDescriptor<WeeklyCheckIn>()) {
            context.delete(checkIn)
        }
        for item in try context.fetch(FetchDescriptor<FocusItem>()) {
            context.delete(item)
        }
        for participant in try context.fetch(FetchDescriptor<CohortParticipant>()) {
            context.delete(participant)
        }
        try save(context)
    }

    private static func makeEvent(
        participant: CohortParticipant,
        name: StudyEventName,
        at date: Date,
        subjectID: UUID? = nil,
        studyWeek: Int? = nil,
        outcome: String? = nil
    ) -> StudyEvent {
        StudyEvent(
            participantID: participant.id,
            name: name,
            occurredAt: date,
            appBuild: appBuild,
            subjectID: subjectID,
            studyWeek: studyWeek,
            outcome: outcome
        )
    }

    private static var appBuild: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "local"
        return "\(version) (\(build))"
    }

    private static func save(_ context: ModelContext) throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw CohortStoreError.persistenceFailed
        }
    }
}
