import XCTest
@testable import LastBeacon

final class LocalizationTests: XCTestCase {
    func testEveryStringHasAllSevenLocalizations() throws {
        let testDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let catalogURL = testDirectory.deletingLastPathComponent()
            .appendingPathComponent("LastBeacon/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(root["strings"] as? [String: Any])
        let locales = ["en", "ko", "zh-Hans", "ja", "es", "fr", "pt-BR"]

        let requiredKeys = Set([
            "app.title", "home.start", "home.endless", "home.settings",
            "missions.title", "results.victory", "results.defeat",
            "settings.title", "settings.music", "settings.effects",
            "settings.haptics", "settings.reduceMotion", "settings.privacy"
        ] + ContentCatalog.launch.upgrades.flatMap { [$0.nameKey, $0.descriptionKey] })
        XCTAssertTrue(requiredKeys.isSubset(of: Set(strings.keys)))

        for (key, rawEntry) in strings {
            let entry = try XCTUnwrap(rawEntry as? [String: Any], "Invalid entry for \(key)")
            let localizations = try XCTUnwrap(entry["localizations"] as? [String: Any], "No localizations for \(key)")
            for locale in locales {
                let localization = try XCTUnwrap(localizations[locale] as? [String: Any], "\(key) lacks \(locale)")
                let unit = try XCTUnwrap(localization["stringUnit"] as? [String: Any])
                let value = try XCTUnwrap(unit["value"] as? String)
                XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(key) is empty in \(locale)")
            }
        }
    }
}
