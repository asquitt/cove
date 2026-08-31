import XCTest

final class CoveGoldenJourneyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing-memory"]
        app.launch()
    }

    func testConsentCaptureReviewCompleteAndActivationJourney() {
        enroll()

        let capture = app.textViews["capture.text"]
        XCTAssertTrue(capture.waitForExistence(timeout: 5))
        capture.tap()
        capture.typeText("Send the revised proposal")
        app.buttons["capture.review"].tap()

        let confirm = app.buttons["review.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        XCTAssertEqual(app.alerts.count, 0)
        confirm.tap()

        let completion = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "task.complete.")
        ).firstMatch
        XCTAssertTrue(completion.waitForExistence(timeout: 5))
        completion.tap()
        XCTAssertTrue(app.alerts.buttons["Complete"].waitForExistence(timeout: 2))
        app.alerts.buttons["Complete"].tap()

        app.tabBars.buttons["Study"].tap()
        let activation = app.descendants(matching: .any)["study.metric.activation"]
        XCTAssertTrue(activation.waitForExistence(timeout: 5))
        XCTAssertTrue(activation.label.contains("Activated: Yes"))
    }

    func testEraseAllDataReturnsToConsent() {
        enroll()
        eraseAllData()
        XCTAssertTrue(app.buttons["consent.begin"].waitForExistence(timeout: 5))
    }

    func testCompletedTaskPersistsAcrossProcessRelaunch() {
        launchWithPersistentStore()
        enroll()

        let capture = app.textViews["capture.text"]
        XCTAssertTrue(capture.waitForExistence(timeout: 5))
        capture.tap()
        capture.typeText("Persist this completed task")
        app.buttons["capture.review"].tap()
        XCTAssertTrue(app.buttons["review.confirm"].waitForExistence(timeout: 5))
        app.buttons["review.confirm"].tap()

        let completion = taskCompletionButton()
        XCTAssertTrue(completion.waitForExistence(timeout: 5))
        completion.tap()
        XCTAssertTrue(app.alerts.buttons["Complete"].waitForExistence(timeout: 2))
        app.alerts.buttons["Complete"].tap()

        app.terminate()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        let persistedCompletion = taskCompletionButton()
        XCTAssertTrue(persistedCompletion.waitForExistence(timeout: 5))
        XCTAssertEqual(persistedCompletion.label, "Completed")

        app.tabBars.buttons["Study"].tap()
        let activation = app.descendants(matching: .any)["study.metric.activation"]
        XCTAssertTrue(activation.waitForExistence(timeout: 5))
        XCTAssertTrue(activation.label.contains("Activated: Yes"))
        eraseAllData(openStudy: false)
    }

    private func enroll() {
        enableSwitch("consent.adult")
        enableSwitch("consent.study")
        app.buttons["consent.begin"].tap()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
    }

    private func enableSwitch(_ identifier: String) {
        let toggle = app.switches[identifier]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "1")
    }

    private func launchWithPersistentStore() {
        app.terminate()
        app.launchArguments = []
        app.launch()

        if !app.buttons["consent.begin"].waitForExistence(timeout: 2) {
            eraseAllData()
            XCTAssertTrue(app.buttons["consent.begin"].waitForExistence(timeout: 5))
        }
    }

    private func taskCompletionButton() -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "task.complete.")
        ).firstMatch
    }

    private func eraseAllData(openStudy: Bool = true) {
        if openStudy {
            app.tabBars.buttons["Study"].tap()
        }
        let erase = app.buttons["study.erase"]
        XCTAssertTrue(erase.waitForExistence(timeout: 5))
        erase.tap()
        XCTAssertTrue(app.alerts.buttons["Erase all local data"].waitForExistence(timeout: 2))
        app.alerts.buttons["Erase all local data"].tap()
    }
}
