import Foundation
import SwiftData

enum CohortSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [PersistentModel.Type] {
        [
            CohortParticipant.self,
            FocusItem.self,
            StudyEvent.self,
            WeeklyCheckIn.self
        ]
    }
}

enum CoveMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [CohortSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

@Model
final class CohortParticipant {
    @Attribute(.unique) var id: UUID
    var consentVersion: String
    var enrolledAt: Date
    var offerPriceCents: Int
    var offerCurrency: String

    init(
        id: UUID = UUID(),
        consentVersion: String,
        enrolledAt: Date = Date(),
        offerPriceCents: Int = 499,
        offerCurrency: String = "USD"
    ) {
        self.id = id
        self.consentVersion = consentVersion
        self.enrolledAt = enrolledAt
        self.offerPriceCents = offerPriceCents
        self.offerCurrency = offerCurrency
    }
}

@Model
final class FocusItem {
    @Attribute(.unique) var id: UUID
    var participantID: UUID
    var rawText: String
    var title: String
    var suggestedBucketRaw: String
    var bucketRaw: String?
    var estimatedMinutes: Int
    var roleRaw: String?
    var stateRaw: String
    var planDayKey: String?
    var createdAt: Date
    var confirmedAt: Date?
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        participantID: UUID,
        rawText: String,
        title: String,
        suggestedBucket: FocusBucket,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participantID = participantID
        self.rawText = rawText
        self.title = title
        self.suggestedBucketRaw = suggestedBucket.rawValue
        self.bucketRaw = nil
        self.estimatedMinutes = 15
        self.roleRaw = nil
        self.stateRaw = FocusState.review.rawValue
        self.planDayKey = nil
        self.createdAt = createdAt
        self.confirmedAt = nil
        self.completedAt = nil
    }

    var suggestedBucket: FocusBucket {
        FocusBucket(rawValue: suggestedBucketRaw) ?? .doNext
    }

    var bucket: FocusBucket? {
        get {
            guard let bucketRaw = bucketRaw else { return nil }
            return FocusBucket(rawValue: bucketRaw)
        }
        set {
            bucketRaw = newValue?.rawValue
        }
    }

    var role: PlanRole? {
        get {
            guard let roleRaw = roleRaw else { return nil }
            return PlanRole(rawValue: roleRaw)
        }
        set {
            roleRaw = newValue?.rawValue
        }
    }

    var state: FocusState {
        get {
            FocusState(rawValue: stateRaw) ?? .review
        }
        set {
            stateRaw = newValue.rawValue
        }
    }
}

@Model
final class StudyEvent {
    @Attribute(.unique) var id: UUID
    var participantID: UUID
    var nameRaw: String
    var occurredAt: Date
    var appBuild: String
    var schemaVersion: Int
    var lifecycleOrder: Int
    var subjectID: UUID?
    var studyWeek: Int?
    var outcome: String?

    init(
        id: UUID = UUID(),
        participantID: UUID,
        name: StudyEventName,
        occurredAt: Date = Date(),
        appBuild: String,
        schemaVersion: Int = 1,
        lifecycleOrder: Int? = nil,
        subjectID: UUID? = nil,
        studyWeek: Int? = nil,
        outcome: String? = nil
    ) {
        self.id = id
        self.participantID = participantID
        self.nameRaw = name.rawValue
        self.occurredAt = occurredAt
        self.appBuild = appBuild
        self.schemaVersion = schemaVersion
        self.lifecycleOrder = lifecycleOrder ?? name.lifecycleOrder
        self.subjectID = subjectID
        self.studyWeek = studyWeek
        self.outcome = outcome
    }

    var name: StudyEventName {
        StudyEventName(rawValue: nameRaw) ?? .captureSubmitted
    }
}

@Model
final class WeeklyCheckIn {
    @Attribute(.unique) var id: UUID
    var participantID: UUID
    var studyWeek: Int
    var submittedAt: Date
    var helpfulness: Int
    var wouldMiss: Int
    var frictionRaw: String
    var willingToPay: Bool
    var offerPriceCents: Int
    var offerCurrency: String

    init(
        id: UUID = UUID(),
        participantID: UUID,
        studyWeek: Int,
        submittedAt: Date = Date(),
        helpfulness: Int,
        wouldMiss: Int,
        friction: FrictionReason,
        willingToPay: Bool,
        offerPriceCents: Int,
        offerCurrency: String
    ) {
        self.id = id
        self.participantID = participantID
        self.studyWeek = studyWeek
        self.submittedAt = submittedAt
        self.helpfulness = helpfulness
        self.wouldMiss = wouldMiss
        self.frictionRaw = friction.rawValue
        self.willingToPay = willingToPay
        self.offerPriceCents = offerPriceCents
        self.offerCurrency = offerCurrency
    }

    var friction: FrictionReason {
        get {
            FrictionReason(rawValue: frictionRaw) ?? .none
        }
        set {
            frictionRaw = newValue.rawValue
        }
    }
}
