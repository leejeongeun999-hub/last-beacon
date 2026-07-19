import XCTest

@MainActor
final class TutorialUITests: XCTestCase {
    func testCompletesInteractiveTutorial() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)"]
        app.launchEnvironment["LAST_BEACON_UI_TEST_RUN_ID"] = UUID().uuidString
        app.launch()

        app.buttons["home.start"].tap()
        app.buttons["mission.sector-1-mission-1"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()

        app.buttons["game.socket.0"].tap()
        XCTAssertTrue(app.buttons["build.pulse"].waitForExistence(timeout: 3))
        app.buttons["build.pulse"].tap()
        app.buttons["game.startWave"].tap()
        app.buttons["game.socket.0"].tap()
        XCTAssertTrue(app.buttons["tower.upgrade"].waitForExistence(timeout: 3))
        app.buttons["tower.upgrade"].tap()

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 3))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["game.socket.0"].exists)
    }
}
