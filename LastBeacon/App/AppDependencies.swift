import Foundation

struct AppDependencies: Sendable {
    let saveStore: any SaveStore

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
        return AppDependencies(saveStore: FileSaveStore(directory: support))
    }
}
