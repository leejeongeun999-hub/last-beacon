# Last Beacon 1.0 release runbook

## Immutable target identity

- Product: Last Beacon: Orbit Defense
- Platform: iPhone, portrait, iOS 17+
- Bundle ID: `com.limeunkyu.lastbeacon`
- Version/build: 1.0.0 (1)
- Repository: `leejeongeun999-hub/last-beacon`
- Controller: `fastlane/Fastfile`

The Apple ID, Developer Team ID, App Store Connect organization, API issuer/key/path, numeric app ID, signing certificate/profile, and three AdMob identities are independent facts. Apple credentials are resolved at runtime from the private release profile; public target identifiers are pinned in the project and preflight. Never copy a value from another app.

## Gates

1. `fastlane ios test`
2. `fastlane ios screenshots`
3. `scripts/release_preflight.sh`
4. `fastlane ios archive`
5. `scripts/verify_ipa.sh build/release/LastBeacon-1.0.0-1.ipa`
6. Upload build, wait for processing, and match bundle/version/build.
7. Upload the seven metadata and screenshot sets.
8. Complete App Privacy, age rating, pricing (free), availability, and review contact from the private release profile.
9. Submit version 1.0.0 build 1 and confirm `Waiting for Review`.

## Advertising and privacy

Google UMP refreshes on every launch and gates Mobile Ads initialization. Interstitials appear only at eligible result transitions; rewarded revive is user initiated and single-use. ATT is intentionally absent because the current binary audit contains no ATT symbol and the planned configuration does not access IDFA. Re-audit the final IPA and update App Privacy answers if the production AdMob configuration changes this data flow.

## Promotion

Only after the IPA, screenshots, metadata, tests, identities, upload processing, and submission evidence are verified may deliverables be copied to `/Users/lim-eunkyu/Desktop/완성작/last-beacon-ios`. Preserve the factory repository and do not delete or overwrite collisions.
