import SwiftUI

struct LegacyBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LegacyColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(LegacyColors.profileRowBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
