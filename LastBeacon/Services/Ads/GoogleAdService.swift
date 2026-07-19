@preconcurrency import GoogleMobileAds

@MainActor
final class GoogleAdService: NSObject, AdServing, FullScreenContentDelegate {
    private struct SDKValue<Value>: @unchecked Sendable {
        let value: Value
    }

    private let configuration: AdUnitConfiguration
    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?
    private var presentingInterstitial: InterstitialAd?
    private var presentingRewarded: RewardedAd?
    private var interstitialContinuation: CheckedContinuation<Void, Never>?
    private var rewardedContinuation: CheckedContinuation<Bool, Never>?
    private var earnedReward = false

    init(configuration: AdUnitConfiguration) {
        self.configuration = configuration
    }

    func prepare() async {
        guard configuration.isUsable else { return }
        await withCheckedContinuation { continuation in
            MobileAds.shared.start { _ in continuation.resume() }
        }
        await loadInterstitial()
        await loadRewarded()
    }

    func presentInterstitial() async {
        guard configuration.isUsable else { return }
        if interstitial == nil { await loadInterstitial() }
        guard let ad = interstitial, (try? ad.canPresent(from: nil)) != nil else { return }
        interstitial = nil
        presentingInterstitial = ad
        ad.fullScreenContentDelegate = self
        await withCheckedContinuation { continuation in
            interstitialContinuation = continuation
            ad.present(from: nil)
        }
    }

    func presentRewardedRevive() async -> Bool {
        guard configuration.isUsable else { return false }
        if rewarded == nil { await loadRewarded() }
        guard let ad = rewarded, (try? ad.canPresent(from: nil)) != nil else { return false }
        rewarded = nil
        presentingRewarded = ad
        earnedReward = false
        ad.fullScreenContentDelegate = self
        return await withCheckedContinuation { continuation in
            rewardedContinuation = continuation
            ad.present(from: nil) { [weak self] in
                self?.earnedReward = true
            }
        }
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        finishPresentation(for: ad)
    }

    func ad(
        _ ad: any FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        finishPresentation(for: ad)
    }

    private func loadInterstitial() async {
        let result: SDKValue<InterstitialAd?> = await withCheckedContinuation { continuation in
            InterstitialAd.load(with: configuration.interstitialID, request: Request()) { ad, _ in
                continuation.resume(returning: SDKValue(value: ad))
            }
        }
        interstitial = result.value
    }

    private func loadRewarded() async {
        let result: SDKValue<RewardedAd?> = await withCheckedContinuation { continuation in
            RewardedAd.load(with: configuration.rewardedID, request: Request()) { ad, _ in
                continuation.resume(returning: SDKValue(value: ad))
            }
        }
        rewarded = result.value
    }

    private func finishPresentation(for ad: any FullScreenPresentingAd) {
        let object = ad as AnyObject
        if let current = presentingInterstitial, object === current {
            presentingInterstitial = nil
            interstitialContinuation?.resume()
            interstitialContinuation = nil
            Task { await loadInterstitial() }
        } else if let current = presentingRewarded, object === current {
            presentingRewarded = nil
            rewardedContinuation?.resume(returning: earnedReward)
            rewardedContinuation = nil
            Task { await loadRewarded() }
        }
    }
}
