import XCTest
@testable import LastBeacon

@MainActor
final class AppModelTests: XCTestCase {
    func testMissionCompletionUpdatesProgressionAndShowsResults() async {
        let store = MemorySaveStore()
        let model = AppModel(dependencies: AppDependencies(saveStore: store))
        await model.load()
        let mission = ContentCatalog.launch.missions[0]

        model.start(mission: mission)
        XCTAssertEqual(model.route, .game(mission))

        let result = RunResult(
            missionID: mission.id,
            victory: true,
            beaconHealth: 90,
            beaconMaximumHealth: 100,
            optionalConditionMet: true,
            salvage: 400
        )
        await model.complete(result: result)

        XCTAssertEqual(model.route, .results(result))
        XCTAssertEqual(model.document.progression.stars(for: mission.id), 3)
        let savedAfterResult = await store.saved()
        XCTAssertEqual(savedAfterResult.progression.stars(for: mission.id), 3)
    }

    func testSettingsPersistImmediately() async {
        let store = MemorySaveStore()
        let model = AppModel(dependencies: AppDependencies(saveStore: store))
        await model.load()

        await model.updateSettings { $0.reduceMotion = true }

        XCTAssertTrue(model.document.settings.reduceMotion)
        let savedAfterSettings = await store.saved()
        XCTAssertTrue(savedAfterSettings.settings.reduceMotion)
    }

    func testTutorialCompletionPersists() async {
        let store = MemorySaveStore()
        let model = AppModel(dependencies: AppDependencies(saveStore: store))
        await model.load()

        await model.markTutorialCompleted()

        XCTAssertTrue(model.document.tutorialCompleted)
        let saved = await store.saved()
        XCTAssertTrue(saved.tutorialCompleted)
    }
}

private actor MemorySaveStore: SaveStore {
    private var document = SaveDocument.default

    func load() async -> SaveDocument { document }
    func save(_ document: SaveDocument) async throws { self.document = document }
    func saved() -> SaveDocument { document }
}
