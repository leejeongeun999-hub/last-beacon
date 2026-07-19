import Foundation

@MainActor
protocol ConsentManaging: AnyObject {
    var canRequestAds: Bool { get }
    var privacyOptionsRequired: Bool { get }
    func refresh() async
    func presentPrivacyOptions() async
}

@MainActor
final class NoopConsentManager: ConsentManaging {
    let canRequestAds = false
    let privacyOptionsRequired = false
    func refresh() async { }
    func presentPrivacyOptions() async { }
}

