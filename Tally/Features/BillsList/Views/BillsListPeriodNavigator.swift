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
                        .font(TallyType.body(16, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(themeColors.accent)
                }
                .frame(maxWidth: .infinity)
                .frame(height: BillsListLayout.periodNavigatorHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("选择期间")

            if showsArrows {
                navButton(systemName: "chevron.right", enabled: canGoNext, action: onNext)
            }
        }
        .padding(.horizontal, TallySpacing.s2)
        .background(Color.tallySurface.opacity(0.72))
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }

    private func navButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled ? themeColors.accent : Color.tallyInkFaint.opacity(0.45))
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
        .accessibilityHidden(!enabled)
    }
}

