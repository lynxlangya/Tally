import SwiftUI

struct JOTabItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let systemImage: String
}

struct JOTabBar: View {
    let items: [JOTabItem]
    @Binding var selectedIndex: Int
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(JOColors.tabBarBackground)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(JOColors.tabBarBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
                .frame(width: width, height: height)

            HStack {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    Button {
                        selectedIndex = index
                    } label: {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(selectedIndex == index ? JOColors.accent : JOColors.tabIconMuted)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(Text(item.title))
                    }
                    .buttonStyle(.plain)
                    .offset(x: index == 0 ? -18 : 18)
                }
            }
            .frame(width: width - 48, height: height)
        }
    }
}
