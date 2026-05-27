import SwiftUI

enum TallyShellTab: Int, CaseIterable, Identifiable {
    case home
    case statistics
    case profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home:
            return "今日"
        case .statistics:
            return "账本"
        case .profile:
            return "我"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .statistics:
            return "chart.xyaxis.line"
        case .profile:
            return "person"
        }
    }
}

struct TallyTabBar: View {
    @Binding var selection: TallyShellTab
    let onFabTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.tallyBg,
                    Color.tallyBg.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 8)

            Rectangle()
                .fill(Color.tallyLineHi)
                .frame(height: 0.5)
                .padding(.horizontal, 24)

            HStack(alignment: .center, spacing: 0) {
                tabButton(.home)
                    .frame(maxWidth: .infinity)
                tabButton(.statistics)
                    .frame(maxWidth: .infinity)
                TallyFAB(action: onFabTap)
                    .frame(width: 84)
                    .offset(y: -12)
                tabButton(.profile)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
            .frame(maxHeight: .infinity)

            Color.clear.frame(height: 28)
        }
        .frame(height: 104)
        .background(
            LinearGradient(
                colors: [
                    Color.tallyBg,
                    Color.tallyBg.opacity(0.6)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    private func tabButton(_ tab: TallyShellTab) -> some View {
        let active = selection == tab
        return Button {
            withAnimation(.tallyFast) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .top) {
                    Circle()
                        .fill(active ? Color.tallyAccent : Color.clear)
                        .frame(width: 4, height: 4)
                        .offset(y: -10)
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 22, weight: active ? .semibold : .medium))
                        .symbolVariant(active ? .fill : .none)
                }
                Text(tab.title)
                    .font(TallyType.body(10.5, weight: active ? .semibold : .medium))
                    .tracking(10.5 * 0.04)
            }
            .foregroundStyle(active ? Color.tallyInk : Color.tallyInkFaint)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(tab.title))
        .accessibilityAddTraits(.isButton)
        .tallySelectedAccessibility(active)
    }
}

private extension View {
    @ViewBuilder
    func tallySelectedAccessibility(_ isSelected: Bool) -> some View {
        if isSelected {
            accessibilityAddTraits(.isSelected)
        } else {
            self
        }
    }
}

#Preview("TallyTabBar Light") {
    TallyTabBarPreview()
        .preferredColorScheme(.light)
}

#Preview("TallyTabBar Dark") {
    TallyTabBarPreview()
        .preferredColorScheme(.dark)
}

private struct TallyTabBarPreview: View {
    @State private var selection: TallyShellTab = .home

    var body: some View {
        VStack {
            Spacer()
            TallyTabBar(selection: $selection) {}
        }
        .background(Color.tallyBg)
    }
}
