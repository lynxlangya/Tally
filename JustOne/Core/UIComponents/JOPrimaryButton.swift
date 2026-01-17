import SwiftUI

struct JOPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(JOTypography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, JOSpacing.md)
        }
        .buttonStyle(JOPrimaryButtonStyle(isEnabled: isEnabled))
        .disabled(!isEnabled)
    }
}

struct JOPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(JOColors.accentForeground)
            .background(isEnabled ? JOColors.accent : JOColors.accent.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: JORadius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .shadow(
                color: JOShadows.floating.color,
                radius: JOShadows.floating.radius,
                x: JOShadows.floating.x,
                y: JOShadows.floating.y
            )
    }
}
