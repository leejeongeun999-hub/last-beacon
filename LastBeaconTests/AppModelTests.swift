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

    func testConsentStartsAdsOnceAndPersistsPrivacyOption() async {
        let store = MemorySaveStore()
        let ads = FakeAdService()
        let consent = FakeConsentManager(canRequestAds: true, privacyOptionsRequired: true)
        let model = AppModel(dependencies: AppDependencies(
            saveStore: store,
            adService: ads,
            consentManager: consent
        ))
        await model.load()

        await model.startAdvertising()
        await model.startAdvertising()

        XCTAssertEqual(consent.refreshCount, 2)
        XCTAssertEqual(ads.prepareCount, 1)
        XCTAssertTrue(model.document.consentCache.privacyOptionsRequired)
    }

    func testSecondCompletedRunPresentsInterstitial() async {
        let store = MemorySaveStore()
        let ads = FakeAdService()
        let model = AppModel(dependencies: AppDependencies(
            saveStore: store,
            adService: ads,
            consentManager: FakeConsentManager(canRequestAds: false, privacyOptionsRequired: false)
        ))
        await model.load()
        let mission = ContentCatalog.launch.missions[0]
        let result = RunResult(
            missionID: mission.id, victory: true,
            beaconHealth: 100, beaconMaximumHealth: 100,
            optionalConditionMet: true, salvage: 100
        )

        await model.complete(result: result)
        XCTAssertEqual(ads.interstitialCount, 0)
        model.start(mission: mission)
        await model.complete(result: result)
        XCTAssertEqual(ads.interstitialCount, 1)
    }
}

private actor MemorySaveStore: SaveStore {
    private var document = SaveDocument.default

    func load() async -> SaveDocument { document }
    func save(_ document: SaveDocument) async throws { self.document = document }
    func saved() -> SaveDocument { document }
}

@MainActor
private final class FakeAdService: AdServing {
    var prepareCount = 0
    var interstitialCount = 0
    var rewardedResult = true

    func prepare() async { prepareCount += 1 }
    func presentInterstitial() async { interstitialCount += 1 }
    func presentRewardedRevive() async -> Bool { rewardedResult }
}

@MainActor
private final class FakeConsentManager: ConsentManaging {
    private(set) var canRequestAds: Bool
    private(set) var privacyOptionsRequired: Bool
    var refreshCount = 0

    init(canRequestAds: Bool, privacyOptionsRequired: Bool) {
        self.canRequestAds = canRequestAds
        self.privacyOptionsRequired = privacyOptionsRequired
    }

    func refresh() async { refreshCount += 1 }
    func presentPrivacyOptions() async { }
}
