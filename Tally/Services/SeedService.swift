import Foundation

protocol SeedService {
    func seedIfNeeded() throws
}

struct StubSeedService: SeedService {
    func seedIfNeeded() throws {}
}
