import XCTest
@testable import LastBeacon

final class SmokeTests: XCTestCase {
    func testProductIdentity() {
        XCTAssertEqual(AppConfiguration.productName, "Last Beacon: Orbit Defense")
        XCTAssertEqual(AppConfiguration.bundleIdentifier, "com.limeunkyu.lastbeacon")
    }
}

