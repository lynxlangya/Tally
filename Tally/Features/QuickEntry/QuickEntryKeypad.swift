import SwiftUI

struct QuickEntryKeypad: View {
    let onKey: (QuickEntryViewModel.KeypadKey) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: QuickEntryLayout.keypadSpacing),
        count: 4
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: QuickEntryLayout.keypadSpacing) {
            keypadButton(.digit(1), title: "1", style: .digit)
            keypadButton(.digit(2), title: "2", style: .digit)
            keypadButton(.digit(3), title: "3", style: .digit)
            keypadButton(.delete, systemImage: "delete.left", style: .action)

            keypadButton(.digit(4), title: "4", style: .digit)
            keypadButton(.digit(5), title: "5", style: .digit)
            keypadButton(.digit(6), title: "6", style: .digit)
            keypadButton(.calendar, systemImage: "calendar", style: .action)

            keypadButton(.digit(7), title: "7", style: .digit)
            keypadButton(.digit(8), title: "8", style: .digit)
            keypadButton(.digit(9), title: "9", style: .digit)
            keypadButton(.minus, title: "−", style: .action)

            keypadButton(.decimal, title: ".", style: .digit)
            keypadButton(.digit(0), title: "0", style: .digit)
            keypadButton(.doubleZero, title: "00", style: .digit)
            keypadButton(.add, title: "+", style: .action)
        }
    }

    private func keypadButton(
        _ key: QuickEntryViewModel.KeypadKey,
        title: String? = nil,
        systemImage: String? = nil,
        style: QuickEntryKeyStyle
    ) -> some View {
        Button {
            onKey(key)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: QuickEntryLayout.keypadCornerRadius, style: .continuous)
                    .fill(style.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: QuickEntryLayout.keypadCornerRadius, style: .continuous)
                            .stroke(Color.tallyLine, lineWidth: 0.5)
                    )

                if let title {
                    Text(title)
                        .font(TallyType.num(QuickEntryLayout.keypadFontSize, weight: .regular))
                        .foregroundStyle(style.foreground)
                }

                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(style.foreground)
                }
            }
            .frame(height: QuickEntryLayout.keypadKeyHeight)
        }
        .buttonStyle(QuickEntryKeyButtonStyle())
    }
}

private enum QuickEntryKeyStyle {
    case digit
    case action

    var background: Color {
        switch self {
        case .digit: return .tallySurface2
        case .action: return .tallySurface
        }
    }

    var foreground: Color {
        switch self {
        case .digit: return .tallyInk
        case .action: return .tallyInkDim
        }
    }
}

private struct QuickEntryKeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.tallySpring, value: configuration.isPressed)
    }
}
