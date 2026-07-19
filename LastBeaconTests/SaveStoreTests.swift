import XCTest
@testable import LastBeacon

final class SaveStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LastBeaconTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testRoundTripPreservesDocument() async throws {
        let store = FileSaveStore(directory: directory)
        var document = SaveDocument.default
        document.tutorialCompleted = true
        document.settings.musicEnabled = false

        try await store.save(document)
        let loaded = await store.load()

        XCTAssertEqual(loaded, document)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("save.tmp").path))
    }

    func testCorruptDataIsBackedUpAndDefaultsLoad() async throws {
        let saveURL = directory.appendingPathComponent("save.json")
        try Data("not-json".utf8).write(to: saveURL)
        let store = FileSaveStore(directory: directory, now: { Date(timeIntervalSince1970: 100) })

        let loaded = await store.load()

        XCTAssertEqual(loaded, .default)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: directory.appendingPathComponent("save.corrupt-100.json").path
        ))
        XCTAssertFalse(FileManager.default.fileExists(atPath: saveURL.path))
    }

    func testFutureVersionIsPreservedAndDefaultsLoad() async throws {
        var future = SaveDocument.default
        future.schemaVersion = SaveDocument.currentVersion + 1
        let data = try JSONEncoder().encode(future)
        try data.write(to: directory.appendingPathComponent("save.json"))
        let store = FileSaveStore(directory: directory, now: { Date(timeIntervalSince1970: 101) })

        let loaded = await store.load()

        XCTAssertEqual(loaded, .default)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: directory.appendingPathComponent("save.future-101.json").path
        ))
    }

    func testSecondSaveAtomicallyReplacesFirst() async throws {
        let store = FileSaveStore(directory: directory)
        var first = SaveDocument.default
        first.statistics.totalRuns = 1
        var second = first
        second.statistics.totalRuns = 2

        try await store.save(first)
        try await store.save(second)

        let loaded = await store.load()
        XCTAssertEqual(loaded.statistics.totalRuns, 2)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(names, ["save.json"])
    }
}
