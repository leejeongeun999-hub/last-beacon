import Foundation

struct AppDependencies: Sendable {
    let saveStore: any SaveStore

    @MainActor
    static var live: AppDependencies {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LastBeacon", isDirectory: true)
        return AppDependencies(saveStore: FileSaveStore(directory: support))
    }
}

