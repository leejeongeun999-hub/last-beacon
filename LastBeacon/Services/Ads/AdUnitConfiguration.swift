import Foundation

struct AdUnitConfiguration: Equatable, Sendable {
    let interstitialID: String
    let rewardedID: String

    var isUsable: Bool {
        interstitialID.hasPrefix("ca-app-pub-")
            && rewardedID.hasPrefix("ca-app-pub-")
            && interstitialID.isEmpty == false
            && rewardedID.isEmpty == false
    }

    static let development = AdUnitConfiguration(
        interstitialID: "ca-app-pub-3940256099942544/4411468910",
        rewardedID: "ca-app-pub-3940256099942544/1712485313"
    )

    static var bundled: AdUnitConfiguration {
        #if DEBUG
        return .development
        #else
        guard let url = Bundle.main.url(forResource: "AdConfiguration", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let values = object as? [String: String] else {
            return AdUnitConfiguration(interstitialID: "", rewardedID: "")
        }
        return AdUnitConfiguration(
            interstitialID: values["ProductionInterstitialID"] ?? "",
            rewardedID: values["ProductionRewardedID"] ?? ""
        )
        #endif
    }
}

