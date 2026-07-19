import Foundation

struct AdInitializationGate: Equatable, Sendable {
    private(set) var initialized = false

    mutating func claimIfAllowed(canRequestAds: Bool) -> Bool {
        guard canRequestAds, initialized == false else { return false }
        initialized = true
        return true
    }

    mutating func reset() {
        initialized = false
    }
}
