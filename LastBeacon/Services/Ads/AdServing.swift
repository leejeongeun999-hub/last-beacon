import Foundation

@MainActor
protocol AdServing: AnyObject {
    func prepare() async
    func presentInterstitial() async
    func presentRewardedRevive() async -> Bool
}

@MainActor
final class NoopAdService: AdServing {
    func prepare() async { }
    func presentInterstitial() async { }
    func presentRewardedRevive() async -> Bool { false }
}

