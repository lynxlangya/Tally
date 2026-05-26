import SwiftUI

struct JOIconButton: View {
    let systemName: String
    let size: CGFloat
    let action: () -> Void

    init(systemName: String, size: CGFloat = 40, action: @escaping () -> Void) {
        self.systemName = systemName
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(JOColors.textPrimary)
                .frame(width: size, height: size)
                .background(JOColors.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(JOColors.divider, lineWidth: 1))
        }
    }
}
