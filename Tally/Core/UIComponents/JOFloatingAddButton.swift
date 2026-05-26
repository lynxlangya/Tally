import SwiftUI

struct JOFloatingAddButton: View {
    let size: CGFloat
    let action: () -> Void

    init(size: CGFloat = 68, action: @escaping () -> Void) {
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(JOColors.fabIcon)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(JOColors.fabGreen)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: JOColors.fabGlow.opacity(0.1), radius: 6, x: 0, y: 0)
                )
        }
        .buttonStyle(.plain)
    }
}
