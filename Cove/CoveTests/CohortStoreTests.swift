import SwiftData
import XCTest
@testable import Cove

@MainActor
final class CohortStoreTests: XCTestCase {
    private func makeStore() throws -> (ModelContainer, ModelContext) {
        let schema = Schema(versionedSchema: CohortSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return (container, ModelContext(container))
    }

    func testFreshStoreContainsNoConsentOrStudyEvents() throws {
        let (_, context) = try makeStore()
        XCTAssertTrue(try context.fetch(FetchDescriptor<CohortParticipant>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<StudyEvent>()).isEmpty)
    }

    func testCapturedThoughtPersistsInReviewStateUntilDecision() throws {
        let (_, context) = try makeStore()
        let participant = try CohortStore.enroll(in: context)
        let captured = try CohortStore.capture("Review this later", participant: participant, in: context)

        let stored = try context.fetch(FetchDescriptor<FocusItem>())
        XCTAssertEqual(stored.map(\.id), [captured.id])
        XCTAssertEqual(stored.first?.state, .review)
        XCTAssertEqual(stored.first?.rawText, "Review this later")
    }

    func testPlanEnforcesThreeAnchorsAndTwoSideQuests() throws {
        let (_, context) = try makeStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let participant = try CohortStore.enroll(in: context, at: start)

        for index in 0..<3 {
            let item = try CohortStore.capture("Anchor \(index)", participant: participant, in: context, at: start)
            try CohortStore.confirm(
                item,
                bucket: .doNext,
                title: item.title,
                estimateMinutes: 15,
                role: .anchor,
                participant: participant,
                in: context,
                at: start
            )
        }

        let fourth = try CohortStore.capture("Fourth anchor", participant: participant, in: context, at: start)
        XCTAssertThrowsError(
            try CohortStore.confirm(
                fourth,
                bucket: .doNext,
                title: fourth.title,
                estimateMinutes: 15,
                role: .anchor,
                participant: participant,
                in: context,
                at: start
            )
        ) { error in
            XCTAssertEqual(error as? CohortStoreError, .planFull(.anchor))
        }

        for index in 0..<2 {
            let item = try CohortStore.capture("Side \(index)", participant: participant, in: context, at: start)
            try CohortStore.confirm(
                item,
                bucket: .doNext,
                title: item.title,
                estimateMinutes: 10,
                role: .sideQuest,
                participant: participant,
                in: context,
                at: start
            )
        }

        let counts = try CohortStore.planCounts(dayKey: DayKey.value(for: start), in: context)
        XCTAssertEqual(counts, PlanCounts(anchors: 3, sideQuests: 2))

        let thirdSideQuest = try CohortStore.capture("Third side", participant: participant, in: context, at: start)
        XCTAssertThrowsError(
            try CohortStore.confirm(
                thirdSideQuest,
                bucket: .doNext,
                title: thirdSideQuest.title,
                estimateMinutes: 10,
                role: .sideQuest,
                participant: participant,
                in: context,
                at: start
            )
        ) { error in
            XCTAssertEqual(error as? CohortStoreError, .planFull(.sideQuest))
        }
    }

    func testCompletionIsIdempotentAndCreatesOneCompletionEvent() throws {
        let (_, context) = try makeStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let participant = try CohortStore.enroll(in: context, at: start)
        let item = try CohortStore.capture("Send the invoice", participant: participant, in: context, at: start)
        try CohortStore.confirm(
            item,
            bucket: .doNext,
            title: item.title,
            estimateMinutes: 10,
            role: .anchor,
            participant: participant,
            in: context,
            at: start
        )

        XCTAssertTrue(try CohortStore.complete(item, participant: participant, in: context, at: start))
        XCTAssertFalse(try CohortStore.complete(item, participant: participant, in: context, at: start))

        let events = try context.fetch(FetchDescriptor<StudyEvent>())
        XCTAssertEqual(events.filter { $0.name == .taskCompleted && $0.subjectID == item.id }.count, 1)
    }

    func testSavedForLaterCanBeAssignedWithoutCreatingAnotherCapture() throws {
        let (_, context) = try makeStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let participant = try CohortStore.enroll(in: context, at: start)
        let item = try CohortStore.capture("Prepare agenda", participant: participant, in: context, at: start)
        try CohortStore.confirm(
            item,
            bucket: .doNext,
            title: item.title,
            estimateMinutes: 15,
            role: nil,
            participant: participant,
            in: context,
            at: start
        )

        XCTAssertNil(item.planDayKey)
        XCTAssertTrue(try CohortStore.assignToToday(
            item,
            role: .anchor,
            participant: participant,
            in: context,
            at: start
        ))
        XCTAssertEqual(item.planDayKey, DayKey.value(for: start))
        XCTAssertEqual(try context.fetch(FetchDescriptor<FocusItem>()).count, 1)
        XCTAssertEqual(
            try context.fetch(FetchDescriptor<StudyEvent>()).filter { $0.name == .taskAssigned }.count,
            1
        )
    }

    func testReleasedTextIsErasedAndNeverAppearsInReport() throws {
        let (_, context) = try makeStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let participant = try CohortStore.enroll(in: context, at: start)
        let secret = "private words that must not be exported"
        let item = try CohortStore.capture(secret, participant: participant, in: context, at: start)
        try CohortStore.confirm(
            item,
            bucket: .release,
            title: item.title,
            estimateMinutes: 15,
            role: nil,
            participant: participant,
            in: context,
            at: start
        )

        XCTAssertEqual(item.rawText, "")
        let events = try context.fetch(FetchDescriptor<StudyEvent>())
        let checkIns = try context.fetch(FetchDescriptor<WeeklyCheckIn>())
        let report = CohortReport.make(participant: participant, events: events, checkIns: checkIns)
        XCTAssertFalse(try report.encodedJSON().contains(secret))
    }

    func testReportExcludesOtherParticipantEventsAndResponses() throws {
        let (_, context) = try makeStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let participant = try CohortStore.enroll(in: context, at: start)
        let otherParticipant = CohortParticipant(consentVersion: CohortStore.consentVersion, enrolledAt: start)
        context.insert(otherParticipant)
        let otherEvent = StudyEvent(
            participantID: otherParticipant.id,
            name: .weeklyFeedbackSubmitted,
            occurredAt: start,
            appBuild: "test",
            studyWeek: 1,
            outcome: "other-participant-canary"
        )
        context.insert(otherEvent)
        let otherCheckIn = WeeklyCheckIn(
            participantID: otherParticipant.id,
            studyWeek: 1,
            helpfulness: 1,
            wouldMiss: 1,
            friction: .other,
            willingToPay: false,
            offerPriceCents: 999,
            offerCurrency: "USD"
        )
        context.insert(otherCheckIn)
        try context.save()

        let report = CohortReport.make(
            participant: participant,
            events: try context.fetch(FetchDescriptor<StudyEvent>()),
            checkIns: try context.fetch(FetchDescriptor<WeeklyCheckIn>())
        )
        let encoded = try report.encodedJSON()
        XCTAssertFalse(encoded.contains("other-participant-canary"))
        XCTAssertFalse(encoded.contains(otherParticipant.id.uuidString))
        XCTAssertTrue(report.checkIns.isEmpty)
    }

    func testWeeklyCheckInPreservesFirstResponseAndDoesNotDuplicate() throws {
        let (_, context) = try makeStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let participant = try CohortStore.enroll(in: context, at: start)

        _ = try CohortStore.submitCheckIn(
            participant: participant,
            helpfulness: 3,
            wouldMiss: 2,
            friction: .tooManySteps,
            willingToPay: false,
            in: context,
            at: start
        )
        _ = try CohortStore.submitCheckIn(
            participant: participant,
            helpfulness: 5,
            wouldMiss: 4,
            friction: .none,
            willingToPay: true,
            in: context,
            at: start.addingTimeInterval(60)
        )

        let checkIns = try context.fetch(FetchDescriptor<WeeklyCheckIn>())
        let events = try context.fetch(FetchDescriptor<StudyEvent>())
        XCTAssertEqual(checkIns.count, 1)
        XCTAssertEqual(checkIns.first?.helpfulness, 3)
        XCTAssertFalse(checkIns.first?.willingToPay == true)
        XCTAssertEqual(events.filter { $0.name == .weeklyFeedbackSubmitted }.count, 1)
    }

    func testWillingnessToPayIsAcceptedOnlyInWeekFour() throws {
        let (_, context) = try makeStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let participant = try CohortStore.enroll(in: context, at: start)

        let weekOne = try CohortStore.submitCheckIn(
            participant: participant,
            helpfulness: 4,
            wouldMiss: 4,
            friction: .none,
            willingToPay: true,
            in: context,
            at: start
        )
        let weekFour = try CohortStore.submitCheckIn(
            participant: participant,
            helpfulness: 5,
            wouldMiss: 5,
            friction: .none,
            willingToPay: true,
            in: context,
            at: start.addingTimeInterval(StudyWeek.duration * 3)
        )

        XCTAssertFalse(weekOne.willingToPay)
        XCTAssertTrue(weekFour.willingToPay)
        let events = try context.fetch(FetchDescriptor<StudyEvent>())
        let checkIns = try context.fetch(FetchDescriptor<WeeklyCheckIn>())
        XCTAssertTrue(StudyMetrics.snapshot(events: events, checkIns: checkIns).statedWillingnessToPay)
    }

    func testDeleteAllRemovesContentConsentAndEvidence() throws {
        let (_, context) = try makeStore()
        let participant = try CohortStore.enroll(in: context)
        _ = try CohortStore.capture("Buy groceries", participant: participant, in: context)

        try CohortStore.deleteAllData(in: context)

        XCTAssertTrue(try context.fetch(FetchDescriptor<CohortParticipant>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<FocusItem>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<StudyEvent>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<WeeklyCheckIn>()).isEmpty)
    }
}
