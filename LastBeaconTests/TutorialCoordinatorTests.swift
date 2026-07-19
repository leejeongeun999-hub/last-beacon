import XCTest
@testable import LastBeacon

final class TutorialCoordinatorTests: XCTestCase {
    func testTutorialAdvancesOnlyOnExpectedActions() {
        var tutorial = TutorialCoordinator()
        XCTAssertEqual(tutorial.step, .welcome)

        tutorial.handle(.startedWave)
        XCTAssertEqual(tutorial.step, .welcome)
        tutorial.handle(.acknowledged)
        XCTAssertEqual(tutorial.step, .buildPulse)
        tutorial.handle(.builtTower(.laser))
        XCTAssertEqual(tutorial.step, .buildPulse)
        tutorial.handle(.builtTower(.pulse))
        XCTAssertEqual(tutorial.step, .startWave)
        tutorial.handle(.startedWave)
        XCTAssertEqual(tutorial.step, .upgradePulse)
        tutorial.handle(.upgradedTower(.pulse))
        XCTAssertEqual(tutorial.step, .complete)
        XCTAssertTrue(tutorial.isComplete)
    }
}
