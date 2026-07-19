import Foundation

actor FileSaveStore: SaveStore {
    private let directory: URL
    private let fileManager: FileManager
    private let now: @Sendable () -> Date

    init(
        directory: URL,
        fileManager: FileManager = .default,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.directory = directory
        self.fileManager = fileManager
        self.now = now
    }

    func load() async -> SaveDocument {
        let saveURL = directory.appendingPathComponent("save.json")
        guard fileManager.fileExists(atPath: saveURL.path) else { return .default }

        do {
            let data = try Data(contentsOf: saveURL)
            let document = try JSONDecoder().decode(SaveDocument.self, from: data)
            guard document.schemaVersion <= SaveDocument.currentVersion else {
                try preserve(saveURL, reason: "future")
                return .default
            }
            return document
        } catch {
            try? preserve(saveURL, reason: "corrupt")
            return .default
        }
    }

    func save(_ document: SaveDocument) async throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let saveURL = directory.appendingPathComponent("save.json")
        let temporaryURL = directory.appendingPathComponent("save.tmp")
        if fileManager.fileExists(atPath: temporaryURL.path) {
            try fileManager.removeItem(at: temporaryURL)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: temporaryURL, options: .completeFileProtectionUnlessOpen)

        if fileManager.fileExists(atPath: saveURL.path) {
            _ = try fileManager.replaceItemAt(saveURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: saveURL)
        }
    }

    private func preserve(_ saveURL: URL, reason: String) throws {
        let timestamp = Int(now().timeIntervalSince1970)
        let backupURL = directory.appendingPathComponent("save.\(reason)-\(timestamp).json")
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.moveItem(at: saveURL, to: backupURL)
    }
}
