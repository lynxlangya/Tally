import SwiftUI

struct AppRootView: View {
    @Environment(\.appEnvironment) private var environment

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Bills") {
                    BillsListView(repository: environment.container.repositories.bill)
                }
                #if DEBUG
                NavigationLink("Debug") {
                    DebugView(
                        repository: environment.container.repositories.bill,
                        seedService: environment.container.services.seed
                    )
                }
                #endif
            }
            .navigationTitle("JustOne")
        }
    }
}

#Preview {
    AppRootView()
        .environment(\.appEnvironment, .preview)
}
