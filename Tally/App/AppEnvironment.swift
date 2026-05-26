import SwiftUI

struct AppEnvironment {
    let container: DIContainer
    let persistenceController: PersistenceController

    static let live: AppEnvironment = {
        let persistence = PersistenceController.shared
        let container = DIContainer.live(persistenceController: persistence)
        return AppEnvironment(container: container, persistenceController: persistence)
    }()

    static let preview: AppEnvironment = {
        let persistence = PersistenceController.preview
        let container = DIContainer.live(persistenceController: persistence)
        return AppEnvironment(container: container, persistenceController: persistence)
    }()
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.live
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
