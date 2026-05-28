import CoreData
import XCTest
@testable import Tally

final class PersistenceControllerTests: XCTestCase {
    @MainActor
    func testStoreLoadFailureMarksStartupAsFailed() {
        let startupState = PersistenceStartupState()

        _ = PersistenceController(
            inMemory: true,
            startupState: startupState,
            storeLoader: { _, completion in
                completion(TestPersistenceError.storeLoad)
            }
        )

        let issue = failedIssue(from: startupState.status)
        XCTAssertEqual(issue?.phase, .storeLoad)
    }

    @MainActor
    func testSeedMigrationFailureMarksStartupAsFailed() async throws {
        let startupState = PersistenceStartupState()

        _ = PersistenceController(
            inMemory: true,
            startupState: startupState,
            storeLoader: { _, completion in
                completion(nil)
            },
            seedRunner: { _ in
                throw TestPersistenceError.seed
            }
        )

        let issue = try await waitForFailedIssue(in: startupState)
        XCTAssertEqual(issue.phase, .seedMigration)
    }

    private func failedIssue(from status: PersistenceStartupStatus) -> PersistenceStartupIssue? {
        guard case .failed(let issue) = status else {
            return nil
        }
        return issue
    }

    @MainActor
    private func waitForFailedIssue(in startupState: PersistenceStartupState) async throws -> PersistenceStartupIssue {
        for _ in 0..<50 {
            if let issue = failedIssue(from: startupState.status) {
                return issue
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Expected persistence startup to fail")
        throw TestPersistenceError.timeout
    }
}

private enum TestPersistenceError: LocalizedError {
    case storeLoad
    case seed
    case timeout

    var errorDescription: String? {
        switch self {
        case .storeLoad:
            return "Injected store load failure"
        case .seed:
            return "Injected seed failure"
        case .timeout:
            return "Timed out waiting for persistence status"
        }
    }
}
