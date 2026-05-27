import SwiftUI

struct AppRootView: View {
    var body: some View {
        TallyTabScaffold()
    }
}

#Preview {
    AppRootView()
        .environment(\.appEnvironment, .preview)
}
