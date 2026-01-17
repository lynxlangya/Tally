import SwiftUI

struct JOTabScaffold: View {
    private enum TabIndex: Int {
        case home = 0
        case profile = 1
    }

    @State private var selectedIndex = TabIndex.home.rawValue
    @State private var showsQuickEntry = false

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
                homeStack
                profileStack

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showsQuickEntry) {
            QuickEntryPlaceholder()
        }
    }

    private var homeStack: some View {
        NavigationStack {
            HomeView()
        }
        .opacity(selectedIndex == TabIndex.home.rawValue ? 1 : 0)
        .allowsHitTesting(selectedIndex == TabIndex.home.rawValue)
    }

    private var profileStack: some View {
        NavigationStack {
            ProfileView()
        }
        .opacity(selectedIndex == TabIndex.profile.rawValue ? 1 : 0)
        .allowsHitTesting(selectedIndex == TabIndex.profile.rawValue)
    }
}

private struct QuickEntryPlaceholder: View {
    var body: some View {
        VStack(spacing: JOSpacing.lg) {
            Text("Quick Entry")
                .font(JOTypography.title)
                .foregroundStyle(JOColors.textPrimary)
            Text("Placeholder")
                .font(JOTypography.body)
                .foregroundStyle(JOColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JOColors.background.ignoresSafeArea())
    }
}

#Preview {
    JOTabScaffold()
        .environment(\.appEnvironment, .preview)
}
