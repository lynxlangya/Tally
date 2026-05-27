import SwiftUI

struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: LegacyRadius.profileRow, style: .continuous)
                    .fill(LegacyColors.profileRowHighlight)
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: LegacyRadius.profileRow, style: .continuous))
    }
}
