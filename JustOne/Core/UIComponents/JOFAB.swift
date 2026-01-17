import SwiftUI

struct JOFAB: View {
    let systemName: String
    let action: () -> Void

    init(systemName: String = "plus", action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(JOColors.accentForeground)
                .frame(width: 64, height: 64)
                .background(JOColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: JORadius.card, style: .continuous))
                .shadow(
                    color: JOShadows.floating.color,
                    radius: JOShadows.floating.radius,
                    x: JOShadows.floating.x,
                    y: JOShadows.floating.y
                )
        }
    }
}
