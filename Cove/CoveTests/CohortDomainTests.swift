import XCTest
@testable import Cove

final class CohortDomainTests: XCTestCase {
    func testClassifierDefaultsToActionButRecognizesKeepAndReleaseSignals() {
        XCTAssertEqual(CohortClassifier.suggest(for: "Send the revised deck"), .doNext)
        XCTAssertEqual(CohortClassifier.suggest(for: "Remember that https://example.com"), .keep)
        XCTAssertEqual(CohortClassifier.suggest(for: "I feel overwhelmed by this"), .release)
    }

    func testTitleCollapsesWhitespaceAndCapsLength() {
        XCTAssertEqual(FocusTitle.make(from: "  Call   the dentist\nnext line"), "Call the dentist")
        XCTAssertEqual(FocusTitle.make(from: String(repeating: "x", count: 120)).count, 80)
    }

    func testDayKeyUsesProvidedCalendar() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = Date(timeIntervalSince1970: 1_735_689_600)
        XCTAssertEqual(DayKey.value(for: date, calendar: calendar), "2025-01-01")
    }

    func testStudyWeeksUseFixedSevenDayWindows() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertEqual(StudyWeek.number(enrolledAt: start, at: start), 1)
        XCTAssertEqual(StudyWeek.number(enrolledAt: start, at: start.addingTimeInterval(StudyWeek.duration - 1)), 1)
        XCTAssertEqual(StudyWeek.number(enrolledAt: start, at: start.addingTimeInterval(StudyWeek.duration)), 2)
    }

    func testMetricsRequireLinkedCompletionInEveryStudyWeek() {
        let participantID = UUID()
        let events = (1...4).flatMap { week -> [StudyEvent] in
            let subjectID = UUID()
            return [
                .captureSubmitted,
                .classificationResolved,
                .captureDecided,
                .taskAssigned,
                .taskCompleted
            ].map { name in
                let outcome: String
                switch name {
                case .captureSubmitted: outcome = "text_local"
                case .classificationResolved, .captureDecided: outcome = FocusBucket.doNext.rawValue
                case .taskAssigned, .taskCompleted: outcome = PlanRole.anchor.rawValue
                case .studyEnrolled, .weeklyFeedbackSubmitted: outcome = ""
                }
                return StudyEvent(
                    participantID: participantID,
                    name: name,
                    occurredAt: Date(),
                    appBuild: "test",
                    subjectID: subjectID,
                    studyWeek: week,
                    outcome: outcome
                )
            }
        }
        let snapshot = StudyMetrics.snapshot(events: events, checkIns: [])
        XCTAssertTrue(snapshot.activated)
        XCTAssertEqual(snapshot.retainedWeeks, [1, 2, 3, 4])
        XCTAssertTrue(snapshot.retainedAllFourWeeks)
        XCTAssertFalse(snapshot.statedWillingnessToPay)
    }

    func testOutOfOrderOrNonActionLineageDoesNotActivateParticipant() {
        let participantID = UUID()
        let subjectID = UUID()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let events = [
            StudyEvent(participantID: participantID, name: .taskCompleted, occurredAt: start, appBuild: "test", subjectID: subjectID, studyWeek: 1, outcome: PlanRole.anchor.rawValue),
            StudyEvent(participantID: participantID, name: .captureSubmitted, occurredAt: start.addingTimeInterval(1), appBuild: "test", subjectID: subjectID, studyWeek: 1, outcome: "text_local"),
            StudyEvent(participantID: participantID, name: .classificationResolved, occurredAt: start.addingTimeInterval(2), appBuild: "test", subjectID: subjectID, studyWeek: 1, outcome: FocusBucket.keep.rawValue),
            StudyEvent(participantID: participantID, name: .captureDecided, occurredAt: start.addingTimeInterval(3), appBuild: "test", subjectID: subjectID, studyWeek: 1, outcome: FocusBucket.keep.rawValue),
            StudyEvent(participantID: participantID, name: .taskAssigned, occurredAt: start.addingTimeInterval(4), appBuild: "test", subjectID: subjectID, studyWeek: 1, outcome: PlanRole.anchor.rawValue)
        ]

        XCTAssertFalse(StudyMetrics.snapshot(events: events, checkIns: []).activated)
    }

    func testUnlinkedCompletionDoesNotActivateParticipant() {
        let event = StudyEvent(
            participantID: UUID(),
            name: .taskCompleted,
            occurredAt: Date(),
            appBuild: "test",
            subjectID: UUID(),
            studyWeek: 1
        )
        let snapshot = StudyMetrics.snapshot(events: [event], checkIns: [])
        XCTAssertFalse(snapshot.activated)
        XCTAssertTrue(snapshot.retainedWeeks.isEmpty)
    }
}
