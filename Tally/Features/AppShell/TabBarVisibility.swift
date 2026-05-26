import SwiftUI

struct TabBarVisibilityAction {
    let setVisible: (Bool) -> Void
}

private struct TabBarVisibilityKey: EnvironmentKey {
    static let defaultValue: TabBarVisibilityAction? = nil
}

extension EnvironmentValues {
    var tabBarVisibility: TabBarVisibilityAction? {
        get { self[TabBarVisibilityKey.self] }
        set { self[TabBarVisibilityKey.self] = newValue }
    }
}
