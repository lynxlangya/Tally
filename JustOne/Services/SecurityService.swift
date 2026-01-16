import Foundation

protocol SecurityService {
    func isLockEnabled() -> Bool
    func authenticate() async throws -> Bool
    func keychainStore(_ data: Data, for key: String) throws
}

struct StubSecurityService: SecurityService {
    func isLockEnabled() -> Bool {
        false
    }

    func authenticate() async throws -> Bool {
        true
    }

    func keychainStore(_ data: Data, for key: String) throws {
        throw ServiceError.notImplemented
    }
}
