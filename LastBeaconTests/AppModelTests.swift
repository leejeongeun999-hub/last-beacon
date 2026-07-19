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

    func testReplayTutorialStartsFirstMissionEvenAfterCompletion() async {
        let store = MemorySaveStore()
        let model = AppModel(dependencies: AppDependencies(saveStore: store))
        await model.load()
        await model.markTutorialCompleted()

        model.replayTutorial()

        XCTAssertTrue(model.forceTutorial)
        XCTAssertEqual(model.route, .game(ContentCatalog.launch.missions[0]))
        await model.markTutorialCompleted()
        XCTAssertFalse(model.forceTutorial)
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

    func testDeniedConsentDisablesAdsAndWithdrawalAllowsFreshPreparation() async {
        let store = MemorySaveStore()
        let ads = FakeAdService()
        let consent = FakeConsentManager(canRequestAds: false, privacyOptionsRequired: true)
        let model = AppModel(dependencies: AppDependencies(
            saveStore: store,
            adService: ads,
            consentManager: consent
        ))
        await model.load()

        await model.startAdvertising()
        XCTAssertEqual(ads.disableCount, 1)
        XCTAssertEqual(ads.prepareCount, 0)

        consent.canRequestAds = true
        await model.startAdvertising()
        XCTAssertEqual(ads.prepareCount, 1)

        consent.canRequestAdsAfterPrivacyOptions = false
        await model.presentPrivacyOptions()
        XCTAssertEqual(ads.disableCount, 2)

        consent.canRequestAds = true
        await model.startAdvertising()
        XCTAssertEqual(ads.prepareCount, 2)
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
        await model.markTutorialCompleted()
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

    func testUnavailableInterstitialDoesNotConsumeCadence() async {
        let store = MemorySaveStore()
        let ads = FakeAdService()
        ads.interstitialResult = false
        let model = AppModel(dependencies: AppDependencies(saveStore: store, adService: ads))
        await model.load()
        let mission = ContentCatalog.launch.missions[0]
        let result = RunResult(
            missionID: mission.id, victory: true,
            beaconHealth: 100, beaconMaximumHealth: 100,
            optionalConditionMet: true, salvage: 100
        )

        await model.complete(result: result)
        await model.complete(result: result)
        XCTAssertEqual(ads.interstitialCount, 1)

        ads.interstitialResult = true
        await model.complete(result: result)
        XCTAssertEqual(ads.interstitialCount, 2)
    }

    func testReplayedTutorialNeverPresentsInterstitial() async {
        let store = MemorySaveStore()
        let ads = FakeAdService()
        let model = AppModel(dependencies: AppDependencies(saveStore: store, adService: ads))
        await model.load()
        await model.markTutorialCompleted()
        let mission = ContentCatalog.launch.missions[0]
        let result = RunResult(
            missionID: mission.id, victory: true,
            beaconHealth: 100, beaconMaximumHealth: 100,
            optionalConditionMet: true, salvage: 100
        )
        await model.complete(result: result)

        model.replayTutorial()
        await model.complete(result: result)

        XCTAssertEqual(ads.interstitialCount, 0)
    }

    func testEndlessUnlockStartsRunAndCompletionSavesHighScore() async {
        let store = MemorySaveStore()
        let model = AppModel(dependencies: AppDependencies(saveStore: store))
        await model.load()

        model.startEndless()
        XCTAssertEqual(model.route, .home)

        await model.complete(result: RunResult(
            missionID: "sector-1-mission-4",
            victory: true,
            beaconHealth: 100,
            beaconMaximumHealth: 100,
            optionalConditionMet: true,
            salvage: 800
        ))
        model.goHome()
        model.startEndless()
        XCTAssertEqual(model.route, .game(LaunchMissions.endless))

        let endlessResult = RunResult(
            missionID: "endless",
            victory: false,
            beaconHealth: 0,
            beaconMaximumHealth: 100,
            optionalConditionMet: false,
            salvage: 1_700
        )
        await model.complete(result: endlessResult)

        XCTAssertEqual(model.document.endlessHighScore, 1_700)
        XCTAssertEqual(model.route, .results(endlessResult))
        let saved = await store.saved()
        XCTAssertEqual(saved.endlessHighScore, 1_700)
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
    var disableCount = 0
    var interstitialCount = 0
    var interstitialResult = true
    var rewardedResult = true

    func prepare() async { prepareCount += 1 }
    func disable() async { disableCount += 1 }
    func presentInterstitial() async -> Bool {
        interstitialCount += 1
        return interstitialResult
    }
    func presentRewardedRevive() async -> Bool { rewardedResult }
}

@MainActor
private final class FakeConsentManager: ConsentManaging {
    var canRequestAds: Bool
    private(set) var privacyOptionsRequired: Bool
    var canRequestAdsAfterPrivacyOptions: Bool?
    var refreshCount = 0

    init(canRequestAds: Bool, privacyOptionsRequired: Bool) {
        self.canRequestAds = canRequestAds
        self.privacyOptionsRequired = privacyOptionsRequired
    }

    func refresh() async { refreshCount += 1 }
    func presentPrivacyOptions() async {
        if let canRequestAdsAfterPrivacyOptions {
            canRequestAds = canRequestAdsAfterPrivacyOptions
        }
    }
}
