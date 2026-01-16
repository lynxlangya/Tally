import SwiftUI

struct AppEnvironment {
    let container: DIContainer
    let persistenceController: PersistenceController

    static let live = AppEnvironment(
        container: DIContainer(),
        persistenceController: PersistenceController.shared
    )
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
