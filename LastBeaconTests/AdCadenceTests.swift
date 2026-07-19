import XCTest
@testable import LastBeacon

final class AdCadenceTests: XCTestCase {
    func testInterstitialAppearsOnlyEverySecondCompletedRun() {
        var cadence = AdCadence()

        XCTAssertFalse(cadence.recordCompletedRun(wasTutorial: true))
        XCTAssertTrue(cadence.recordCompletedRun(wasTutorial: false))
        XCTAssertFalse(cadence.recordCompletedRun(wasTutorial: false))
        XCTAssertTrue(cadence.recordCompletedRun(wasTutorial: false))
    }

    func testTutorialNeverShowsInterstitialEvenAtCadenceBoundary() {
        var cadence = AdCadence(completedRuns: 1, lastInterstitialRun: 0)

        XCTAssertFalse(cadence.recordCompletedRun(wasTutorial: true))
        XCTAssertEqual(cadence.completedRuns, 2)
    }

    func testRewardGateGrantsExactlyOncePerRun() {
        var gate = RewardGrantGate(runID: UUID())

        XCTAssertTrue(gate.consumeReward())
        XCTAssertFalse(gate.consumeReward())
    }

    func testDevelopmentAdConfigurationUsesGoogleTestUnits() {
        let configuration = AdUnitConfiguration.development

        XCTAssertEqual(configuration.interstitialID, "ca-app-pub-3940256099942544/4411468910")
        XCTAssertEqual(configuration.rewardedID, "ca-app-pub-3940256099942544/1712485313")
        XCTAssertTrue(configuration.isUsable)
    }
}
