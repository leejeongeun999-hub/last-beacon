import XCTest
@testable import LastBeacon

final class ContentCatalogTests: XCTestCase {
    func testLaunchCatalogHasExactScope() throws {
        let catalog = ContentCatalog.launch

        XCTAssertEqual(catalog.missions.count, 12)
        XCTAssertEqual(catalog.upgrades.count, 24)
        XCTAssertEqual(Set(catalog.missions.map(\.sector)).count, 3)
        XCTAssertEqual(catalog.missions.filter { $0.sector == 1 }.count, 4)
        XCTAssertEqual(catalog.missions.filter { $0.sector == 2 }.count, 4)
        XCTAssertEqual(catalog.missions.filter { $0.sector == 3 }.count, 4)
        XCTAssertTrue(catalog.missions.allSatisfy { $0.waves.count == 8 })
        XCTAssertTrue(catalog.missions.allSatisfy { $0.waves.last?.spawns.last?.kind == .sectorBoss })
        XCTAssertNoThrow(try catalog.validate())
    }

    func testCatalogRejectsDuplicateMissionIdentifiers() {
        let mission = ContentCatalog.launch.missions[0]
        let catalog = ContentCatalog(
            missions: [mission, mission],
            upgrades: ContentCatalog.launch.upgrades,
            sectorModifiers: ContentCatalog.launch.sectorModifiers
        )

        XCTAssertThrowsError(try catalog.validate()) { error in
            XCTAssertEqual(error as? ContentValidationError, .duplicateMissionID(mission.id))
        }
    }

    func testCatalogRejectsInvalidLane() {
        let invalid = MissionDefinition(
            id: "invalid",
            sector: 1,
            startingEnergy: 100,
            beaconHealth: 100,
            waves: [WaveDefinition(spawns: [EnemySpawn(time: 0, kind: .drone, lane: 3)])]
        )
        let catalog = ContentCatalog(
            missions: [invalid],
            upgrades: ContentCatalog.launch.upgrades,
            sectorModifiers: [.solarWind]
        )

        XCTAssertThrowsError(try catalog.validate()) { error in
            XCTAssertEqual(error as? ContentValidationError, .invalidLane(missionID: "invalid", lane: 3))
        }
    }

    func testSameSeedOffersSameThreeDistinctUpgrades() {
        let first = UpgradeOffering.make(from: ContentCatalog.launch.upgrades, seed: 99)
        let second = UpgradeOffering.make(from: ContentCatalog.launch.upgrades, seed: 99)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 3)
        XCTAssertEqual(Set(first.map(\.id)).count, 3)
    }

    func testUpgradeOffersExcludeDefinitionsAlreadyAtMaximumTier() {
        let upgrades = [
            UpgradeDefinition(id: "maxed", nameKey: "a", descriptionKey: "b", category: .pulse, maximumTier: 1),
            UpgradeDefinition(id: "open", nameKey: "c", descriptionKey: "d", category: .laser, maximumTier: 2)
        ]

        let offer = UpgradeOffering.make(from: upgrades, seed: 1, count: 3, appliedIDs: ["maxed"])

        XCTAssertEqual(offer.map(\.id), ["open"])
    }

    func testEndlessMissionProvidesLongCappedScaling() {
        let endless = LaunchMissions.endless

        XCTAssertTrue(endless.isEndless)
        XCTAssertEqual(endless.waves.count, 120)
        XCTAssertTrue(endless.waves.allSatisfy { $0.spawns.count <= 25 })
        XCTAssertTrue(endless.waves.enumerated().allSatisfy { index, wave in
            (index + 1).isMultiple(of: 8)
                ? wave.spawns.last?.kind == .sectorBoss
                : true
        })
    }
}
