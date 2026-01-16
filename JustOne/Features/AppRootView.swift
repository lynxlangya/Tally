import SwiftUI

struct AppRootView: View {
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        NavigationStack {
            BillsListView(repository: environment.container.repositories.bill)
        }
    }
}

#Preview {
    AppRootView()
        .environment(\.appEnvironment, .preview)
}
