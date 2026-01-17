import SwiftUI

struct JOBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(JOColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(JOColors.profileRowBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
