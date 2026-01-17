import SwiftUI

struct JODestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.red.opacity(0.9))
            .background(Color.red.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: JORadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: JORadius.button, style: .continuous)
                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
