import UserMessagingPlatform

@MainActor
final class GoogleConsentManager: ConsentManaging {
    private let information = ConsentInformation.shared

    var canRequestAds: Bool { information.canRequestAds }

    var privacyOptionsRequired: Bool {
        information.privacyOptionsRequirementStatus == .required
    }

    func refresh() async {
        let parameters = RequestParameters()
        await withCheckedContinuation { continuation in
            information.requestConsentInfoUpdate(with: parameters) { _ in
                continuation.resume()
            }
        }
        await withCheckedContinuation { continuation in
            ConsentForm.loadAndPresentIfRequired(from: nil) { _ in
                continuation.resume()
            }
        }
    }

    func presentPrivacyOptions() async {
        guard privacyOptionsRequired else { return }
        await withCheckedContinuation { continuation in
            ConsentForm.presentPrivacyOptionsForm(from: nil) { _ in
                continuation.resume()
            }
        }
    }
}
