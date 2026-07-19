import XCTest
@testable import LastBeacon

final class ConsentTests: XCTestCase {
    func testAdInitializationCanBeClaimedOnlyOnce() {
        var gate = AdInitializationGate()

        XCTAssertTrue(gate.claimIfAllowed(canRequestAds: true))
        XCTAssertFalse(gate.claimIfAllowed(canRequestAds: true))
        XCTAssertFalse(gate.claimIfAllowed(canRequestAds: false))
    }

    func testInitializationWaitsUntilConsentAllowsAds() {
        var gate = AdInitializationGate()

        XCTAssertFalse(gate.claimIfAllowed(canRequestAds: false))
        XCTAssertTrue(gate.claimIfAllowed(canRequestAds: true))
    }

    func testInitializationCanBeResetAfterConsentWithdrawal() {
        var gate = AdInitializationGate()

        XCTAssertTrue(gate.claimIfAllowed(canRequestAds: true))
        gate.reset()

        XCTAssertTrue(gate.claimIfAllowed(canRequestAds: true))
    }
}
