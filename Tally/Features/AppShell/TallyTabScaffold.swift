import SwiftUI

struct TallyTabScaffold: View {
    @Environment(\.appEnvironment) private var environment

    @State private var selectedTab: TallyShellTab = .home
    @State private var showsQuickEntry = false
    @State private var tabBarVisible = true

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                homeStack
                    .tag(TallyShellTab.home)
                statisticsStack
                    .tag(TallyShellTab.statistics)
                profileStack
                    .tag(TallyShellTab.profile)
            }
            .toolbar(.hidden, for: .tabBar)
            .environment(
                \.tabBarVisibility,
                TabBarVisibilityAction { isVisible in
                    withAnimation(.tallyBase) {
                        tabBarVisible = isVisible
                    }
                }
            )

            if tabBarVisible {
                TallyTabBar(selection: $selectedTab) {
                    showsQuickEntry = true
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .sheet(isPresented: $showsQuickEntry) {
            QuickEntryView(
                repository: environment.container.repositories.bill,
                categoryRepository: environment.container.repositories.category,
                suggestionService: environment.container.services.categorySuggestion
            )
        }
    }

    private var homeStack: some View {
        NavigationStack {
            HomeView(
                repository: environment.container.repositories.bill,
                categoryRepository: environment.container.repositories.category,
                suggestionService: environment.container.services.categorySuggestion
            )
            .enableInteractivePop()
        }
    }

    private var statisticsStack: some View {
        NavigationStack {
            BillsListView(
                repository: environment.container.repositories.bill,
                categoryRepository: environment.container.repositories.category,
                suggestionService: environment.container.services.categorySuggestion,
                hidesTabBarOnAppear: false
            )
            .enableInteractivePop()
        }
    }

    private var profileStack: some View {
        NavigationStack {
            ProfileView(
                billRepository: environment.container.repositories.bill,
                categoryRepository: environment.container.repositories.category,
                recurringRepository: environment.container.repositories.recurring
            )
            .enableInteractivePop()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let route = DeepLinkRouter.parse(url) else { return }
        switch route {
        case .quickEntry:
            selectedTab = .home
            showsQuickEntry = true
        case .home:
            selectedTab = .home
        case .statistics:
            selectedTab = .statistics
        }
    }
}

#Preview {
    TallyTabScaffold()
        .environment(\.appEnvironment, .preview)
}
