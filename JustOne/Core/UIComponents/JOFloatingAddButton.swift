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
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(JOColors.fabGreen)
                        .shadow(color: JOColors.fabGlow.opacity(0.45), radius: 32, x: 0, y: 14)
                        .shadow(color: JOColors.fabGlow.opacity(0.8), radius: 14, x: 0, y: 6)
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
                )
        }
        .buttonStyle(.plain)
    }
}
