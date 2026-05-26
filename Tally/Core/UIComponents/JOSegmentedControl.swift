import SwiftUI

struct JOSegmentedControl: View {
    let items: [String]
    @Binding var selectedIndex: Int

    private enum Constants {
        static let backgroundOpacity: CGFloat = 0.78
        static let selectedOpacity: CGFloat = 1.0
        static let selectedHighlightOpacity: CGFloat = 0.7
        static let borderOpacity: CGFloat = 0.05
        static let controlHeight: CGFloat = 44
        static let outerInsetHorizontal: CGFloat = 8
        static let outerInsetVertical: CGFloat = 6
        static let selectedTextOpacity: CGFloat = 0.96
        static let unselectedTextOpacity: CGFloat = 0.55
        static let animationDuration: Double = 0.2
    }

    init(items: [String], selectedIndex: Binding<Int>) {
        self.items = items
        self._selectedIndex = selectedIndex
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let innerWidth = width - Constants.outerInsetHorizontal * 2
                let innerHeight = height - Constants.outerInsetVertical * 2
                let segmentWidth = innerWidth / CGFloat(max(items.count, 1))

                Capsule(style: .continuous)
                    .fill(JOColors.surface.opacity(Constants.backgroundOpacity))

                Capsule(style: .continuous)
                    .fill(JOColors.surface.opacity(Constants.selectedOpacity))
                    .overlay(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(Constants.selectedHighlightOpacity))
                            .blendMode(.softLight)
                    )
                    .frame(width: segmentWidth, height: innerHeight)
                    .offset(x: Constants.outerInsetHorizontal + CGFloat(selectedIndex) * segmentWidth,
                            y: Constants.outerInsetVertical)
                    .animation(.easeInOut(duration: Constants.animationDuration), value: selectedIndex)
            }

            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    Button {
                        selectedIndex = index
                    } label: {
                        Text(items[index])
                            .font(JOTypography.caption)
                            .fontWeight(selectedIndex == index ? .semibold : .regular)
                            .foregroundStyle(
                                selectedIndex == index
                                ? Color.white.opacity(Constants.selectedTextOpacity)
                                : Color.white.opacity(Constants.unselectedTextOpacity)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Constants.outerInsetHorizontal)
            .padding(.vertical, Constants.outerInsetVertical)
        }
        .frame(height: Constants.controlHeight)
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(Constants.borderOpacity), lineWidth: 1)
        )
    }
}
