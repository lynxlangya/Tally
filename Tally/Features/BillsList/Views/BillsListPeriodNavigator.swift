import SwiftUI

struct BillsListPeriodNavigator: View {
    let title: String
    let showsArrows: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onTitleTap: () -> Void

    @Environment(\.tallyThemeColors) private var themeColors

    var body: some View {
        HStack(spacing: TallySpacing.s3) {
            if showsArrows {
                navButton(systemName: "chevron.left", enabled: true, action: onPrevious)
            }

            Button {
                onTitleTap()
            } label: {
                HStack(spacing: TallySpacing.s2) {
                    Text(title)
                        .font(TallyType.body(14, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.tallyInkDim)
                }
                .frame(minWidth: showsArrows ? 98 : 106)
                .frame(height: BillsListLayout.periodNavigatorHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("选择期间")

            if showsArrows {
                navButton(systemName: "chevron.right", enabled: canGoNext, action: onNext)
            }
        }
    }

    private func navButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(enabled ? Color.tallyInkDim : Color.tallyInkFaint.opacity(0.38))
                .frame(width: 17, height: 32)
                .contentShape(Circle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
        .accessibilityHidden(!enabled)
    }
}
