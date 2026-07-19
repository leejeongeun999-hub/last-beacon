import XCTest
@testable import LastBeacon

@MainActor
final class GameCenterQueueTests: XCTestCase {
    func testFailedSubmissionQueuesOnceAndRemovesOnlyAfterSuccess() async {
        let service = FakeGameCenter(authenticated: true, submissionResults: [false, true])
        var queue = GameCenterSubmissionQueue()

        queue.enqueue(leaderboardID: "endless", value: 120)
        queue.enqueue(leaderboardID: "endless", value: 120)
        XCTAssertEqual(queue.pending.count, 1)

        await queue.flush(using: service)
        XCTAssertEqual(queue.pending.count, 1)

        await queue.flush(using: service)
        XCTAssertTrue(queue.pending.isEmpty)
    }

    func testAuthenticationPromptOccursAtMostOnceAndQueueRetriesAfterAuthentication() async {
        let service = FakeGameCenter(authenticated: false, submissionResults: [true])
        var queue = GameCenterSubmissionQueue()
        queue.enqueue(leaderboardID: "endless", value: 900)

        await queue.flush(using: service)
        await queue.flush(using: service)
        XCTAssertEqual(service.authenticationRequests, 1)
        XCTAssertEqual(queue.pending.count, 1)

        service.authenticated = true
        await queue.flush(using: service)
        XCTAssertTrue(queue.pending.isEmpty)
        XCTAssertEqual(service.authenticationRequests, 1)
    }
}

@MainActor
private final class FakeGameCenter: GameCenterServing {
    var authenticated: Bool
    var authenticationRequests = 0
    private var submissionResults: [Bool]

    init(authenticated: Bool, submissionResults: [Bool]) {
        self.authenticated = authenticated
        self.submissionResults = submissionResults
    }

    func authenticate() async -> Bool {
        authenticationRequests += 1
        return authenticated
    }

    func submit(score: Int, leaderboardID: String) async -> Bool {
        submissionResults.isEmpty ? false : submissionResults.removeFirst()
    }
}
