import SwiftUI

struct AppRootView: View {
    var body: some View {
        JOTabScaffold()
    }
}

#Preview {
    AppRootView()
        .environment(\.appEnvironment, .preview)
}
