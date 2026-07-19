import XCTest
@testable import LastBeacon

final class GameClockTests: XCTestCase {
    func testCapsLongFrameAndPauses() {
        var clock = GameClock(maximumCatchUp: 0.25)

        XCTAssertEqual(clock.consume(elapsed: 1), 0.25)
        clock.isPaused = true
        XCTAssertEqual(clock.consume(elapsed: 0.1), 0)
        clock.isPaused = false
        XCTAssertEqual(clock.consume(elapsed: 0.1), 0.1)
    }

    func testRejectsNegativeAndNonFiniteElapsedTime() {
        var clock = GameClock()

        XCTAssertEqual(clock.consume(elapsed: -1), 0)
        XCTAssertEqual(clock.consume(elapsed: .infinity), 0)
        XCTAssertEqual(clock.consume(elapsed: .nan), 0)
    }
}

