import SwiftUI

struct JOTabScaffold: View {
    @Environment(\.appEnvironment) private var environment

    private enum TabIndex: Int {
        case home = 0
        case profile = 1
    }

    @State private var selectedIndex = TabIndex.home.rawValue
    @State private var showsQuickEntry = false
    @State private var tabBarVisible = true

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = proxy.safeAreaInsets.bottom
            let tabBarHeight: CGFloat = 66
            let tabBarHorizontalInset: CGFloat = 48
            let tabBarWidth = max(260, proxy.size.width - tabBarHorizontalInset * 2)
            let tabBarBottomPadding = max(12, bottomInset - 6)
            let tabBarVerticalOffset: CGFloat = 40
            let fabSize: CGFloat = 68
            let fabLift: CGFloat = 28

            ZStack(alignment: .bottom) {
                TabView(selection: $selectedIndex) {
                    homeStack
                        .tag(TabIndex.home.rawValue)
                    profileStack
                        .tag(TabIndex.profile.rawValue)
                }
                .toolbar(.hidden, for: .tabBar)
                .environment(
                    \.tabBarVisibility,
                    TabBarVisibilityAction { isVisible in
                        tabBarVisible = isVisible
                    }
                )

                if tabBarVisible {
                    JOTabBar(
                        items: [
                            JOTabItem(title: "Home", systemImage: "house.fill"),
                            JOTabItem(title: "Profile", systemImage: "person.fill")
                        ],
                        selectedIndex: $selectedIndex,
                        width: tabBarWidth,
                        height: tabBarHeight
                    )
                    .padding(.bottom, tabBarBottomPadding)
                    .offset(y: tabBarVerticalOffset)
                    .zIndex(1)

                    JOFloatingAddButton(size: fabSize) {
                        showsQuickEntry = true
                    }
                    .padding(.bottom, tabBarBottomPadding + fabLift)
                    .offset(y: tabBarVerticalOffset)
                    .zIndex(2)
                }
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .ignoresSafeArea(.keyboard)
    .sheet(isPresented: $showsQuickEntry) {
            QuickEntryView(
                repository: environment.container.repositories.bill,
                categoryRepository: environment.container.repositories.category
            )
        }
    }

    private var homeStack: some View {
        NavigationStack {
            HomeView(
                repository: environment.container.repositories.bill,
                categoryRepository: environment.container.repositories.category
            )
        }
    }

    private var profileStack: some View {
        NavigationStack {
            ProfileView()
        }
    }
}

#Preview {
    JOTabScaffold()
        .environment(\.appEnvironment, .preview)
}
