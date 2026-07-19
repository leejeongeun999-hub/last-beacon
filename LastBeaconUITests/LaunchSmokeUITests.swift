import XCTest

@MainActor
final class LaunchSmokeUITests: XCTestCase {
    func testLaunchesInSevenLocales() {
        for locale in ["en", "ko", "zh-Hans", "ja", "es", "fr", "pt-BR"] {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(locale))"]
            app.launch()
            XCTAssertTrue(app.buttons["home.start"].waitForExistence(timeout: 5), locale)
            XCTAssertTrue(app.staticTexts["home.title"].exists, locale)
            app.terminate()
        }
    }
}
