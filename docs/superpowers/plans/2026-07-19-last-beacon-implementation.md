# Last Beacon 1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, verify, localize, monetize, package, and submit the iPhone game Last Beacon: Orbit Defense 1.0 to App Store Review.

**Architecture:** SwiftUI owns application navigation and accessible interface screens, while SpriteKit renders a deterministic pure-Swift combat simulation. Persistence, advertising, consent, audio, haptics, and Game Center are behind small protocols so tests run without network services or third-party UI.

**Tech Stack:** Swift 6, SwiftUI, SpriteKit, XCTest, XcodeGen, Google Mobile Ads SDK 13.4.x with UMP, GameKit, AVFoundation, Fastlane, App Store Connect API or an already authenticated Apple session.

## Global Constraints

- Repository: `/Users/lim-eunkyu/Desktop/공장/앱개발/last-beacon-ios`.
- Platform: iPhone portrait, minimum iOS 17.
- Product name: `Last Beacon: Orbit Defense`; Korean display name: `라스트 비콘`.
- Bundle identifier: `com.limeunkyu.lastbeacon`; never infer signing, App Store Connect, or AdMob identity from sibling projects.
- Version 1.0 contains twelve missions, endless mode, three towers, five regular enemies, three bosses, and twenty-four upgrades.
- Locales: `en`, `ko`, `zh-Hans`, `ja`, `es`, `fr`, and `pt-BR`; English is the development fallback.
- No account, server, multiplayer, story dialogue, character collection, energy timer, push notification, or in-app purchase.
- Interstitials appear only on results and at most once per two completed runs; rewarded revive restores 40% health once per run.
- UMP refreshes every launch, ads initialize once only when ads may be requested, and ATT is included only if the final tracking audit requires it.
- All source and staging stay under `~/Desktop/공장`; only verified release deliverables may be promoted to `~/Desktop/완성작`.

## File map

- `project.yml`: XcodeGen project, targets, packages, signing-neutral build settings, and locale resources.
- `LastBeacon/App`: app lifecycle, dependency container, navigation, theme, and app configuration.
- `LastBeacon/GameModel`: deterministic combat state, commands, content definitions, progression, and seeded randomness.
- `LastBeacon/GameScene`: SpriteKit presentation and player input adapter; it does not own combat rules.
- `LastBeacon/Features`: menu, mission select, game host, results, settings, tutorial, and privacy views.
- `LastBeacon/Services`: save, ads, consent, audio, haptics, and Game Center boundaries and production adapters.
- `LastBeacon/Resources`: string catalog, assets, audio, privacy manifest, and configuration plist.
- `LastBeaconTests`: pure model, persistence, advertising cadence, consent, and localization tests.
- `LastBeaconUITests`: seven-locale launch, tutorial, result, settings, and screenshot flows.
- `fastlane`: metadata, screenshot, build, upload, and release lanes tied only to the target repository.
- `scripts`: deterministic content, localization, asset, archive, and IPA verification helpers.

---

### Task 1: Reproducible iPhone project and baseline test

**Files:**
- Create: `AGENTS.md`
- Create: `README.md`
- Create: `.gitignore`
- Create: `project.yml`
- Create: `LastBeacon/App/LastBeaconApp.swift`
- Create: `LastBeacon/Features/Home/HomeView.swift`
- Create: `LastBeaconTests/SmokeTests.swift`

**Interfaces:**
- Produces: Xcode scheme `LastBeacon`, test target `LastBeaconTests`, UI test target `LastBeaconUITests`, bundle ID `com.limeunkyu.lastbeacon`.

- [ ] **Step 1: Add repository-local identity and safety instructions**

Create `AGENTS.md` identifying this repository, bundle ID, iPhone platform, factory/release paths, and the prohibition on sibling identity reuse. Create `README.md` with `xcodegen generate` and `xcodebuild test` commands. Ignore `.DS_Store`, `DerivedData`, `.build`, `build`, `*.xcarchive`, `*.ipa`, `fastlane/report.xml`, private keys, and private profiles.

- [ ] **Step 2: Write the baseline failing smoke test**

```swift
import XCTest
@testable import LastBeacon

final class SmokeTests: XCTestCase {
    func testProductIdentity() {
        XCTAssertEqual(AppConfiguration.productName, "Last Beacon: Orbit Defense")
        XCTAssertEqual(AppConfiguration.bundleIdentifier, "com.limeunkyu.lastbeacon")
    }
}
```

- [ ] **Step 3: Generate a project and confirm the test fails**

Run `xcodegen generate && xcodebuild test -project LastBeacon.xcodeproj -scheme LastBeacon -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:LastBeaconTests/SmokeTests`.

Expected: compile failure because `AppConfiguration` does not exist.

- [ ] **Step 4: Add the minimal app shell**

```swift
import SwiftUI

enum AppConfiguration {
    static let productName = "Last Beacon: Orbit Defense"
    static let bundleIdentifier = "com.limeunkyu.lastbeacon"
}

@main
struct LastBeaconApp: App {
    var body: some Scene { WindowGroup { HomeView() } }
}
```

`HomeView` shows the localized game title and a disabled Start button over the shared neon theme.

- [ ] **Step 5: Verify and commit**

Run the smoke test again and expect `** TEST SUCCEEDED **`. Then run `git diff --check` and commit with `feat: scaffold Last Beacon iPhone app`.

### Task 2: Deterministic combat model

**Files:**
- Create: `LastBeacon/GameModel/CombatTypes.swift`
- Create: `LastBeacon/GameModel/GameState.swift`
- Create: `LastBeacon/GameModel/GameEngine.swift`
- Create: `LastBeacon/GameModel/SeededGenerator.swift`
- Create: `LastBeaconTests/GameEngineTests.swift`

**Interfaces:**
- Produces: `GameEngine.init(mission:seed:)`, `GameEngine.send(_:)`, `GameEngine.advance(by:)`, `GameEngine.snapshot`, and value types `TowerKind`, `EnemyKind`, `Tower`, `Enemy`, `GameCommand`, `GameSnapshot`.

- [ ] **Step 1: Write failing tests for damage, armor, slow, selling, and beacon damage**

```swift
func testLaserIgnoresArmor() {
    var engine = GameEngine.fixture(enemy: .armoredFrigate)
    engine.send(.build(kind: .laser, socket: 0))
    engine.advance(by: 2)
    XCTAssertLessThan(engine.snapshot.enemies[0].health, 100)
}

func testSellingReturnsSeventyPercent() {
    var engine = GameEngine.fixture(energy: 100)
    engine.send(.build(kind: .pulse, socket: 0))
    engine.send(.sell(socket: 0))
    XCTAssertEqual(engine.snapshot.energy, 94)
}
```

Add focused tests for Pulse cooldown, Gravity slow, shield regeneration after three seconds without damage, Splitter children, pause-on-placement, and defeat at zero beacon health.

- [ ] **Step 2: Run tests and verify model symbols are missing**

Run `xcodebuild test -project LastBeacon.xcodeproj -scheme LastBeacon -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:LastBeaconTests/GameEngineTests` and expect compile failures for `GameEngine` and combat types.

- [ ] **Step 3: Implement immutable public snapshots around private mutable state**

Define stable integer IDs, fixed three-lane paths, six sockets, energy costs, three tower levels, damage types, armor reduction, shield timing, slow caps, and command validation. Use fixed-step simulation at `1.0 / 60.0` seconds and a seeded SplitMix64 generator; never read wall-clock time inside combat.

- [ ] **Step 4: Verify deterministic equality**

Add a test that runs two engines with the same mission, seed, commands, and time steps, then asserts identical `GameSnapshot` values. Run the whole `GameEngineTests` suite and expect success.

- [ ] **Step 5: Commit**

Run `git diff --check` and commit with `feat: add deterministic tower defense engine`.

### Task 3: Validated launch content and progression

**Files:**
- Create: `LastBeacon/GameModel/ContentCatalog.swift`
- Create: `LastBeacon/GameModel/Missions.swift`
- Create: `LastBeacon/GameModel/Upgrades.swift`
- Create: `LastBeacon/GameModel/Progression.swift`
- Create: `LastBeaconTests/ContentCatalogTests.swift`
- Create: `LastBeaconTests/ProgressionTests.swift`

**Interfaces:**
- Produces: `ContentCatalog.launch`, `ContentCatalog.validate()`, `MissionDefinition`, `WaveDefinition`, `UpgradeDefinition`, `Progression.apply(result:)`.
- Consumes: Task 2 combat types and seeded generator.

- [ ] **Step 1: Write failing catalog-count and validation tests**

```swift
func testLaunchCatalogHasExactScope() throws {
    let catalog = ContentCatalog.launch
    XCTAssertEqual(catalog.missions.count, 12)
    XCTAssertEqual(catalog.upgrades.count, 24)
    XCTAssertEqual(Set(catalog.missions.map(\.sector)).count, 3)
    XCTAssertNoThrow(try catalog.validate())
}
```

Add failures for duplicate IDs, missing bosses, invalid wave times, an unavailable tower reference, and an upgrade without localized keys.

- [ ] **Step 2: Run tests and verify failure**

Expected: compile failure for missing catalog types.

- [ ] **Step 3: Implement exact launch content**

Define four missions per sector, eight waves per normal mission, a boss at wave eight, sector modifiers `solarWind`, `ionStorm`, and `darkMatter`, twenty-four named upgrades, and endless wave scaling capped to avoid integer overflow. Mission 1 is the four-minute tutorial variant.

- [ ] **Step 4: Implement three-star progression**

Award stars for victory, at least 60% beacon health, and mission-specific optional condition. Sector 2 requires six total stars; sector 3 requires eighteen. Endless unlocks after mission 4 victory.

- [ ] **Step 5: Verify and commit**

Run catalog and progression tests, then commit with `feat: add missions upgrades and progression`.

### Task 4: Versioned atomic persistence

**Files:**
- Create: `LastBeacon/Services/Save/SaveDocument.swift`
- Create: `LastBeacon/Services/Save/SaveStore.swift`
- Create: `LastBeacon/Services/Save/FileSaveStore.swift`
- Create: `LastBeaconTests/SaveStoreTests.swift`

**Interfaces:**
- Produces: `protocol SaveStore { func load() async -> SaveDocument; func save(_:) async throws }` and `SaveDocument.currentVersion`.

- [ ] **Step 1: Write failing tests for round-trip, atomic replacement, corrupt backup, and future version backup**

Use a test-owned temporary directory. Verify corrupt bytes remain at `save.corrupt-<timestamp>.json`, safe defaults load, and the temporary file never remains after a successful save.

- [ ] **Step 2: Run tests and verify failure**

Expected: missing `SaveStore` and `SaveDocument` symbols.

- [ ] **Step 3: Implement actor-isolated persistence**

`FileSaveStore` is an actor. It encodes sorted JSON to a sibling temporary URL, uses `FileManager.replaceItemAt`, and preserves undecodable input before returning defaults. The document stores stars, mission results, settings, tutorial state, statistics, UMP cache fields, pending Game Center scores, and endless high score.

- [ ] **Step 4: Verify and commit**

Run `SaveStoreTests` and commit with `feat: add resilient local save data`.

### Task 5: Seven-locale SwiftUI shell and accessible flows

**Files:**
- Create: `LastBeacon/App/AppModel.swift`
- Create: `LastBeacon/App/AppDependencies.swift`
- Create: `LastBeacon/App/NeonTheme.swift`
- Modify: `LastBeacon/Features/Home/HomeView.swift`
- Create: `LastBeacon/Features/Missions/MissionSelectView.swift`
- Create: `LastBeacon/Features/Results/ResultsView.swift`
- Create: `LastBeacon/Features/Settings/SettingsView.swift`
- Create: `LastBeacon/Resources/Localizable.xcstrings`
- Create: `LastBeaconTests/LocalizationTests.swift`
- Create: `LastBeaconUITests/LaunchUITests.swift`

**Interfaces:**
- Produces: `AppModel`, `AppRoute`, `AppDependencies.live`, localized keys used by every visible view.
- Consumes: `ContentCatalog`, `Progression`, and `SaveStore`.

- [ ] **Step 1: Write failing localization completeness test**

Load `Localizable.xcstrings` as JSON, assert all seven locale codes exist for every required key, and reject empty translations or raw `%` format mismatches.

- [ ] **Step 2: Add the seven-locale catalog**

Include product, menu, mission, tower, enemy, upgrade, tutorial, results, settings, privacy, accessibility, error, and ad-unavailable strings. Use `String(localized:)` or `Text` localization keys; do not embed visible strings in Swift.

- [ ] **Step 3: Build navigation and settings**

Create home, mission grid, results, and settings with the near-black/cyan/magenta/amber palette. Settings independently persist music, effects, haptics, Reduce Motion, and privacy options visibility.

- [ ] **Step 4: Add accessibility and locale UI tests**

Launch once per locale with `-AppleLanguages`, assert the localized title and Start control exist, and verify accessibility identifiers rather than translated labels. Test larger content size and Reduce Motion launch arguments.

- [ ] **Step 5: Verify and commit**

Run unit and UI tests on `iPhone 17 Pro`, inspect no truncation in captured test attachments, and commit with `feat: add localized accessible app flows`.

### Task 6: SpriteKit battlefield and tutorial

**Files:**
- Create: `LastBeacon/GameScene/BattlefieldScene.swift`
- Create: `LastBeacon/GameScene/BattlefieldRenderer.swift`
- Create: `LastBeacon/GameScene/BattlefieldInput.swift`
- Create: `LastBeacon/GameScene/GameClock.swift`
- Create: `LastBeacon/Features/Game/GameHostView.swift`
- Create: `LastBeacon/Features/Tutorial/TutorialCoordinator.swift`
- Create: `LastBeaconTests/GameClockTests.swift`
- Create: `LastBeaconUITests/TutorialUITests.swift`

**Interfaces:**
- Produces: `GameHostView(mission:onFinish:)`, `BattlefieldScene.apply(snapshot:)`, and `TutorialCoordinator` state transitions.
- Consumes: Task 2 `GameEngine` commands and snapshots.

- [ ] **Step 1: Write failing clock and tutorial transition tests**

Verify fixed-step accumulation, pause, maximum catch-up, Reduce Motion choice, and tutorial sequence `welcome → buildPulse → startWave → upgradePulse → finishWave → complete`.

- [ ] **Step 2: Implement geometric rendering**

Draw three fixed lanes, six sockets, cyan beacon, distinct tower silhouettes, enemy silhouettes, projectiles, health bars, energy, wave counter, speed-normalized effects, and opaque HUD panels using SpriteKit primitives. Missing textures are not fatal because the launch renderer requires no gameplay texture assets.

- [ ] **Step 3: Connect one-handed input**

Tapping a socket pauses simulation and opens an accessible SwiftUI build sheet. Tapping a tower opens upgrade/sell actions. Wave start and upgrade choice remain reachable through SwiftUI overlays with VoiceOver labels.

- [ ] **Step 4: Implement mission 1 tutorial and result callback**

Tutorial prompts allow only the highlighted safe action, persist completion, and are skipped on replay unless selected from Settings. Completion returns a deterministic `RunResult` to the app model.

- [ ] **Step 5: Verify and commit**

Run model, clock, and tutorial UI tests; profile the largest launch wave in a release simulator build; commit with `feat: render playable Last Beacon missions`.

### Task 7: Consent-gated advertising with test and production identities

**Files:**
- Modify: `project.yml`
- Create: `LastBeacon/Services/Ads/AdServing.swift`
- Create: `LastBeacon/Services/Ads/AdCadence.swift`
- Create: `LastBeacon/Services/Ads/GoogleAdService.swift`
- Create: `LastBeacon/Services/Consent/ConsentManaging.swift`
- Create: `LastBeacon/Services/Consent/GoogleConsentManager.swift`
- Create: `LastBeacon/Resources/AdConfiguration.plist`
- Create: `LastBeaconTests/AdCadenceTests.swift`
- Create: `LastBeaconTests/ConsentTests.swift`

**Interfaces:**
- Produces: `AdServing.prepare()`, `presentInterstitial(from:)`, `presentRewardedRevive(from:)`, `ConsentManaging.refresh()`, `canRequestAds`, and `privacyOptionsRequired`.

- [ ] **Step 1: Write failing policy tests**

Verify no tutorial or first-run ad, an interstitial on every second later result only, no in-game interstitial, one rewarded revive per run, 40% restore, no reward on dismiss/failure, and exactly-once reward on duplicate SDK callbacks.

- [ ] **Step 2: Implement protocol fakes and cadence before adding the SDK**

`AdCadence` is a pure value type persisted through `SaveDocument`. Result presentation asks the service only when cadence permits. Rewarded completion uses a run-scoped token consumed atomically.

- [ ] **Step 3: Add Google packages and test identifiers**

Add `https://github.com/googleads/swift-package-manager-google-mobile-ads.git` from `13.4.0`, product dependencies `GoogleMobileAds` and `UserMessagingPlatform`, and Google's official iOS test app/interstitial/rewarded IDs in a development-only configuration plist. Production builds fail a preflight if target-specific production IDs are absent or equal to test IDs.

- [ ] **Step 4: Implement UMP launch sequence and single ad initialization**

Call consent-information update on each launch, load/present a required form, expose privacy options when required, and gate `MobileAds.shared.start()` behind `canRequestAds`. Use an actor boolean to prevent duplicate initialization when both cached and refreshed paths allow requests.

- [ ] **Step 5: Verify four privacy paths and commit**

Tests cover UMP required/not required and ATT required/not required independently. Development UI tests use test-device/debug geography configuration without production identifiers. Commit with `feat: add consent gated rewarded and interstitial ads`.

### Task 8: Audio, haptics, Game Center, and privacy manifest

**Files:**
- Create: `LastBeacon/Services/Audio/AudioServing.swift`
- Create: `LastBeacon/Services/Haptics/HapticServing.swift`
- Create: `LastBeacon/Services/GameCenter/GameCenterServing.swift`
- Create: `LastBeacon/Resources/PrivacyInfo.xcprivacy`
- Create: `LastBeaconTests/GameCenterQueueTests.swift`

**Interfaces:**
- Produces: service protocols with no-op/test/live adapters; pending-score queue integrated with `SaveDocument`.

- [ ] **Step 1: Write failing pending-score tests**

Verify a failed endless-score submission queues once, retries after authentication, removes only on success, and never prompts repeatedly.

- [ ] **Step 2: Implement nonblocking services**

Use generated ambient tones and short system-safe synthesized effects stored as assets; settings independently gate music, effects, and haptics. Game Center authentication and leaderboard submission failures never block play.

- [ ] **Step 3: Add the app privacy manifest and SDK audit script**

Declare only APIs actually used by first-party code. Add `scripts/audit_privacy.sh` to enumerate embedded SDK privacy manifests and linked tracking frameworks without printing credentials.

- [ ] **Step 4: Verify and commit**

Run service tests and the privacy audit against a simulator app; commit with `feat: add optional platform services and privacy manifest`.

### Task 9: Visual identity, app icon, and seven-locale store assets

**Files:**
- Create: `LastBeacon/Resources/Assets.xcassets/AppIcon.appiconset/*`
- Create: `LastBeacon/Resources/Assets.xcassets/Brand.imageset/*`
- Create: `scripts/capture_screenshots.sh`
- Create: `scripts/validate_store_assets.sh`
- Create: `fastlane/metadata/<locale>/*`
- Create: `fastlane/screenshots/<locale>/*`
- Create: `docs/release/store-copy.md`

**Interfaces:**
- Produces: opaque 1024×1024 app icon, localized store copy, and three 6.9-inch portrait screenshots per locale at an Apple-accepted size.

- [ ] **Step 1: Create and visually inspect the neon-space brand assets**

Generate a cyan beacon on a near-black star field with magenta hostile silhouettes, no text, no alpha in the final icon. Render the app icon and representative screens, inspect at full and small sizes, and correct muddy glow, unsafe edges, or unreadable silhouettes.

- [ ] **Step 2: Add screenshot fixture mode**

Launch arguments select deterministic mission, seed, locale, consent fake, and capture state. Capture home, active defense, and upgrade choice for all seven locales on a simulator whose native output maps to an accepted 6.9-inch portrait size.

- [ ] **Step 3: Write localized metadata**

Provide name, subtitle, promotional text, description, keywords, support URL, privacy URL, review notes, category Games/Strategy, age-rating answers, and copyright. Copy avoids unverified superlatives and states the ad-supported model accurately.

- [ ] **Step 4: Validate every asset**

The validator checks locale set, three screenshots each, exact accepted dimensions retrieved on 2026-07-19, PNG/JPEG type, no alpha, nonempty metadata, keyword limits, and screenshot collision hashes. Preserve failed outputs for diagnosis.

- [ ] **Step 5: Commit**

Commit with `assets: add verified localized App Store presentation`.

### Task 10: Release controller, full QA, and signed artifact verification

**Files:**
- Create: `fastlane/Appfile`
- Create: `fastlane/Fastfile`
- Create: `scripts/release_preflight.sh`
- Create: `scripts/verify_ipa.sh`
- Create: `docs/release/RELEASE_RUNBOOK.md`
- Create: `docs/release/evidence/.gitkeep`

**Interfaces:**
- Produces: lanes `test`, `screenshots`, `archive`, `upload_build`, `upload_metadata`, and `submit`; release evidence tied to bundle ID and App Store numeric app ID.

- [ ] **Step 1: Write the repository release runbook and nonmutating preflight**

Record independent fields for Apple ID, Developer Team, App Store Connect organization, issuer/key/path, bundle ID, numeric app ID, signing certificate, provisioning profile, AdMob IDs, repository, and controller. The script reports missing target-specific evidence without reading key contents or borrowing sibling values.

- [ ] **Step 2: Add deterministic test and screenshot lanes**

`test` regenerates the project, resolves packages, runs unit/UI tests, validates localization, and audits privacy. `screenshots` captures and validates all seven locale sets. Both stop on first failure and write reports under factory staging.

- [ ] **Step 3: Run complete QA and repair failures**

Run clean build, all unit tests, all UI tests, seven-locale visual QA, ad/consent debug modes, accessibility audit, largest-wave performance check, privacy audit, and store-asset validation. Any unexpected failure triggers systematic debugging before edits.

- [ ] **Step 4: Resolve exact target identities and archive**

Use target-specific authenticated evidence to register or verify `com.limeunkyu.lastbeacon`, create the App Store Connect app record, create the exact AdMob app and ad units, publish the exact UMP message, and configure signing. Never print or commit secrets. Archive version `1.0`, build `1`, and export an IPA under factory staging.

- [ ] **Step 5: Inspect the actual IPA**

Extract to a temporary directory; verify bundle ID, version, build, AdMob app ID, export compliance, entitlements, signature, embedded provisioning Team ID/application ID/UUID/expiration/distribution, privacy manifests, and absence of test ad IDs. Compare independently with the exact App Store Connect record and evidence file.

- [ ] **Step 6: Commit release automation**

Commit with `release: add verified App Store delivery workflow`.

### Task 11: Upload, submit, monitor, and promote the verified release

**Files:**
- Modify: `docs/release/evidence/release-1.0-build-1.md`
- Create: `/Users/lim-eunkyu/Desktop/완성작/last-beacon-ios/` only after verification passes.

**Interfaces:**
- Consumes: exact target App Store Connect app/version IDs, signed IPA, localized assets, privacy answers, and processed build.
- Produces: App Review submission and verified final deliverable package.

- [ ] **Step 1: Upload the exact build and wait for processing**

Upload with the repository controller. Confirm receipt is not treated as completion. Poll the exact app/build until processing completes, then record any warnings and confirm the selectable build matches bundle `com.limeunkyu.lastbeacon`, version `1.0`, and build `1`.

- [ ] **Step 2: Upload metadata and screenshots**

Upload the seven locale metadata and screenshot sets, support/privacy URLs, age rating, category, copyright, review contact from the private profile without logging it, review notes, App Privacy answers based on the final SDK audit, pricing as free, and availability.

- [ ] **Step 3: Submit for App Review**

Attach the processed build, add version 1.0 to a submission, submit it, and verify the item status reaches `Waiting for Review`. Preserve confirmation evidence tied to the numeric app/version/build IDs.

- [ ] **Step 4: Monitor through resolution**

Monitor the exact submission. If Apple reports an issue, preserve the message, diagnose it against the built artifact and current policy, implement and verify the smallest fix, upload an incremented build, and resubmit. Do not change release identities.

- [ ] **Step 5: Promote verified deliverables**

After submission evidence and artifact verification are complete, copy the source bundle, signed IPA/archive evidence, screenshots, metadata, test reports, and release record to `/Users/lim-eunkyu/Desktop/완성작/last-beacon-ios/`. Verify byte identity and completeness. Preserve the factory repository and all collisions; do not delete source or staging.

- [ ] **Step 6: Final verification**

Run `git status --short`, confirm required artifacts and evidence exist, verify the public listing after approval if the release mode is automatic, and record final App Store status without exposing account or credential data.
