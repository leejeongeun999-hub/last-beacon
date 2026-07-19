import Foundation

protocol SaveStore: Sendable {
    func load() async -> SaveDocument
    func save(_ document: SaveDocument) async throws
}

