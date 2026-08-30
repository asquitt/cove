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
        app.tabBars.buttons["Study"].tap()

        let erase = app.buttons["study.erase"]
        XCTAssertTrue(erase.waitForExistence(timeout: 5))
        erase.tap()
        XCTAssertTrue(app.alerts.buttons["Erase all local data"].waitForExistence(timeout: 2))
        app.alerts.buttons["Erase all local data"].tap()

        XCTAssertTrue(app.buttons["consent.begin"].waitForExistence(timeout: 5))
    }

    private func enroll() {
        let adult = app.switches["consent.adult"]
        let study = app.switches["consent.study"]
        XCTAssertTrue(adult.waitForExistence(timeout: 5))
        adult.tap()
        study.tap()
        app.buttons["consent.begin"].tap()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
    }
}
