import SwiftUI

enum AppConfiguration {
    static let productName = "Last Beacon: Orbit Defense"
    static let bundleIdentifier = "com.limeunkyu.lastbeacon"
}

@main
struct LastBeaconApp: App {
    var body: some Scene {
        WindowGroup { HomeView() }
    }
}
