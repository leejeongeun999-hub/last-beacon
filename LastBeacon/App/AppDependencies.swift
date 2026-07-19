import Foundation

@MainActor
struct AppDependencies {
    let saveStore: any SaveStore
    let adService: any AdServing
    let consentManager: any ConsentManaging

    init(
        saveStore: any SaveStore,
        adService: any AdServing = NoopAdService(),
        consentManager: any ConsentManaging = NoopConsentManager()
    ) {
        self.saveStore = saveStore
        self.adService = adService
        self.consentManager = consentManager
    }

    @MainActor
    static var live: AppDependencies {
        let support: URL
        if let testRunID = ProcessInfo.processInfo.environment["LAST_BEACON_UI_TEST_RUN_ID"] {
            support = FileManager.default.temporaryDirectory
                .appendingPathComponent("LastBeaconUITests", isDirectory: true)
                .appendingPathComponent(testRunID, isDirectory: true)
        } else {
            support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("LastBeacon", isDirectory: true)
        }
        return AppDependencies(
            saveStore: FileSaveStore(directory: support),
            adService: GoogleAdService(configuration: .bundled),
            consentManager: GoogleConsentManager()
        )
    }
}
