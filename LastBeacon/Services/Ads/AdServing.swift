import Foundation

@MainActor
protocol AdServing: AnyObject {
    func prepare() async
    func disable() async
    func presentInterstitial() async -> Bool
    func presentRewardedRevive() async -> Bool
}

@MainActor
final class NoopAdService: AdServing {
    func prepare() async { }
    func disable() async { }
    func presentInterstitial() async -> Bool { false }
    func presentRewardedRevive() async -> Bool { false }
}
