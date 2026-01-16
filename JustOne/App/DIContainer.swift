import Foundation

final class DIContainer {
    struct Repositories {
        init() {}
    }

    struct Services {
        init() {}
    }

    let repositories: Repositories
    let services: Services

    init(repositories: Repositories = Repositories(), services: Services = Services()) {
        self.repositories = repositories
        self.services = services
    }
}
