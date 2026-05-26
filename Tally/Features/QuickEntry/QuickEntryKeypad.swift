import SwiftUI

struct QuickEntryKeypad: View {
    let onKey: (QuickEntryViewModel.KeypadKey) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: QuickEntryLayout.keypadSpacing), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: QuickEntryLayout.keypadSpacing) {
            key(.digit(1), title: "1")
            key(.digit(2), title: "2")
            key(.digit(3), title: "3")
            key(.delete, icon: "delete.left")

            key(.digit(4), title: "4")
            key(.digit(5), title: "5")
            key(.digit(6), title: "6")
            key(.calendar, icon: "calendar")

            key(.digit(7), title: "7")
            key(.digit(8), title: "8")
            key(.digit(9), title: "9")
            key(.minus, icon: "minus")

            key(.decimal, title: ".", font: .system(size: QuickEntryLayout.keypadFontSize, weight: .bold))
            key(.digit(0), title: "0")
            key(.doubleZero, title: "00")
            key(.add, icon: "plus")
        }
    }

    private func key(
        _ key: QuickEntryViewModel.KeypadKey,
        title: String? = nil,
        icon: String? = nil,
        isEnabled: Bool = true,
        font: Font = .system(size: QuickEntryLayout.keypadFontSize, weight: .medium)
    ) -> some View {
        Button {
            onKey(key)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: QuickEntryLayout.keypadCornerRadius, style: .continuous)
                    .fill(JOColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: QuickEntryLayout.keypadCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )

                if let title {
                    Text(title)
                        .font(font)
                        .foregroundStyle(JOColors.textPrimary)
                }

                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: QuickEntryLayout.keypadFontSize, weight: .medium))
                        .foregroundStyle(JOColors.textSecondary)
                }
            }
            .frame(height: QuickEntryLayout.keypadKeyHeight)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}
