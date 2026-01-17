import SwiftUI

struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: JORadius.profileRow, style: .continuous)
                    .fill(JOColors.profileRowHighlight)
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: JORadius.profileRow, style: .continuous))
    }
}
