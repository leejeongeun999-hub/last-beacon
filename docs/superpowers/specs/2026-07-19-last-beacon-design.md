# Last Beacon: Orbit Defense — Product Design

## Product identity

- Product name: `Last Beacon: Orbit Defense`
- Korean display name: `라스트 비콘`
- Repository: `/Users/lim-eunkyu/Desktop/공장/앱개발/last-beacon-ios`
- Platform: iPhone
- Orientation: portrait
- Minimum iOS version: iOS 17
- Bundle identifier: `com.limeunkyu.lastbeacon`
- Business model: free, advertising-supported
- Primary session length: 5–10 minutes

The repository configuration and verified release artifacts are the authority for this new product. No Apple team, App Store Connect organization, signing identity, AdMob application, or credential identity may be copied or inferred from a sibling project.

## Player promise

The player protects the last deep-space communications beacon through eight short waves. Each run combines fixed-lane tower defense with one meaningful upgrade choice between waves. The game is immediately understandable, supports one-handed play, and creates replayability through enemy order and upgrade combinations rather than a large amount of authored content.

## Core loop

1. Select one of twelve missions or endless mode.
2. Enter a portrait battlefield with three enemy lanes and six fixed tower sockets.
3. Spend energy to build or upgrade Pulse, Laser, and Gravity towers.
4. Defeat a wave and choose one of three randomly offered run upgrades.
5. Survive eight waves and defeat the sector boss, or lose when beacon health reaches zero.
6. Receive salvage based on waves cleared and mission objectives.
7. Unlock subsequent missions and return to mission selection.

Normal missions target six to eight minutes. The tutorial mission targets under four minutes.

## Combat rules

### Towers

- Pulse Cannon: low damage, short cooldown, effective against swarms.
- Laser Lance: high damage, long cooldown, ignores armor.
- Gravity Well: no direct damage, slows all enemies within its lane segment.

Every tower has three levels. Building and upgrading use energy earned by destroying enemies. Selling returns 70% of energy spent. Tower placement pauses combat so one-handed players are not punished while making a choice.

### Enemies

- Drone: baseline speed and health.
- Swarm: low health, high count.
- Armored Frigate: high armor, vulnerable to Laser Lance.
- Shield Vessel: regenerating shield after avoiding damage for three seconds.
- Splitter: creates two drones when destroyed.
- Sector Boss: one bespoke combination of existing mechanics per sector.

Enemies follow fixed paths. No dynamic pathfinding is required. A wave ends when all spawned enemies are destroyed or reach the beacon.

### Run upgrades

After waves 2, 4, and 6, the player chooses one of three upgrades. The launch build contains 24 upgrades distributed across tower-specific power, economy, beacon defense, and mixed-build synergy. Duplicate upgrades stack only when the upgrade explicitly defines a second tier.

The random offer uses a seeded generator. A run can therefore be reproduced in tests and diagnosed from its stored seed.

## Content scope

- Three sectors with distinct palettes and one mechanical modifier each.
- Four missions per sector, for twelve missions total.
- One endless mode unlocked after mission 4.
- Three tower types, each with three levels.
- Five regular enemy types and three bosses.
- Twenty-four run upgrades.
- A five-step interactive tutorial embedded in mission 1.
- No account, server, multiplayer, story dialogue, character collection, energy timer, push notification, or in-app purchase in version 1.0.

## Progression and save data

Mission completion awards one to three stars for victory, beacon health, and optional mission condition. Stars unlock later sectors. Salvage is a score shown in results and Game Center leaderboards only; it is not spent on permanent power.

Local save data contains completed missions, earned stars, settings, tutorial state, statistics, consent-state cache, and the current endless high score. Saves use a versioned Codable document written atomically. Invalid or future-version data is preserved as a backup and replaced with safe defaults; the player is not blocked from launching.

## Advertising and privacy

- No ad appears during the tutorial or the player's first completed run.
- Interstitial ads may appear only on the results screen and no more often than once every two completed runs.
- A rewarded ad may restore the beacon to 40% health once per run after defeat.
- No banner ad is used.
- When an ad is unavailable, gameplay continues without delay and the unavailable reward action is hidden.
- Reward is granted exactly once and only after the ad SDK reports completed reward eligibility.
- Google UMP consent information is refreshed on every launch. Ads initialize once and only after the SDK reports that ads may be requested.
- ATT is not shown unless the final SDK configuration and data-flow audit demonstrates tracking under Apple's current definition.
- Version 1.0 uses contextual/non-personalized behavior where consent or platform state requires it.

Production AdMob identifiers must be created for this exact product and verified against the built application. Test identifiers are used in development and never promoted as production identity.

## Localization

The launch build supports exactly these locales:

- Korean (`ko`)
- English (`en`)
- Simplified Chinese (`zh-Hans`)
- Japanese (`ja`)
- Spanish (`es`)
- French (`fr`)
- Brazilian Portuguese (`pt-BR`)

English is the development language and fallback. All visible text uses string catalogs; no user-facing strings are embedded in game code or textures. Localization includes menus, tutorial text, tower and enemy names, upgrade descriptions, settings, accessibility labels, privacy options, ad-unavailable messaging, and App Store metadata. Layout testing covers text expansion, truncation, line wrapping, and font fallback in all seven locales.

## Presentation

The game uses a clean neon-space visual language: near-black background, cyan beacon, magenta enemies, amber energy, and white interface text. Units are readable geometric silhouettes with restrained glow. The three lanes and six sockets remain visually stable across sectors.

Audio consists of one looping ambient track, one combat layer, seven short effects, and haptic feedback. Music, effects, and haptics have separate settings. The game remains fully playable without sound.

## Accessibility

- Color is never the only indicator of tower or enemy type; silhouettes and icons remain distinct.
- Essential HUD text meets high-contrast targets over opaque panels.
- Reduce Motion replaces camera shake and large movement transitions with fades.
- VoiceOver labels and hints cover menus, mission selection, tower sockets, upgrade choices, results, settings, and privacy options.
- Dynamic Type applies to menus and informational sheets; the fixed game HUD uses tested scalable presets.

## Technical architecture

- Swift 6 and SwiftUI provide app lifecycle, navigation, menus, settings, localization, accessibility, and results.
- SpriteKit renders and updates deterministic combat.
- Gameplay rules live in a pure Swift model independent of SpriteKit nodes.
- Content definitions are typed Swift data so launch content is validated at build and test time.
- A `GameClock` controls simulation time and supports pause, speed normalization, and deterministic tests.
- `AdServing` and `ConsentManaging` protocols isolate third-party advertising SDK behavior.
- `SaveStore` isolates versioned local persistence.
- Game Center integration is optional at runtime and cannot block play.

The app operates offline except for advertising, consent configuration, and Game Center. Network failures never block missions or results.

## Error handling

- Invalid content definitions fail tests and produce safe diagnostic assertions in development builds.
- Missing optional audio or visual assets fall back to silent audio or geometric placeholders without terminating a run.
- Advertising errors dismiss the ad flow and return to the current screen without granting an incomplete reward.
- Save decoding failures preserve the original data and start a clean profile.
- Game Center authentication and score submission failures are queued locally for a later attempt without repeated prompts.

## Verification and release gates

- Unit tests cover damage, armor, shields, slowing, energy, tower upgrades, wave completion, seeded upgrade offers, star calculation, ad cadence, one-time reward, and save migration.
- UI tests cover first launch, tutorial, mission completion, defeat and revive, settings, privacy options, and all seven locale launch paths.
- Visual QA uses current iPhone simulator sizes and checks every App Store screenshot localization.
- Performance testing targets a stable 60 frames per second with the largest launch wave on the oldest supported device class available for testing.
- Release builds must verify bundle ID, version, build number, entitlements, signing team, provisioning profile, AdMob app ID, privacy manifests, and export-compliance fields from the archived artifact.
- Submission does not proceed until current Apple screenshot requirements, Google UMP guidance, Apple privacy rules, App Store metadata, and target-specific account identities are reverified from authoritative sources.

## Definition of done

Version 1.0 is complete when the twelve missions and endless mode are playable in all seven locales; gameplay, save, accessibility, privacy, consent, and ad tests pass; final localized screenshots and store metadata are verified; a signed distribution artifact matches the target repository identity; the build is processed in the exact App Store Connect app record; and the version is submitted for App Review without unresolved warnings or identity conflicts.
