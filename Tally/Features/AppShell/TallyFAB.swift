import SwiftUI

struct TallyFAB: View {
    let action: () -> Void

    @GestureState private var isPressed = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.tallyAccent)
                .frame(width: 68, height: 68)
                .overlay(
                    TallyMark(
                        size: 26,
                        variant: .one,
                        color: .tallyAccentInk,
                        strokeWidth: 3.2
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        .padding(1),
                    alignment: .top
                )
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.18), lineWidth: 2)
                        .padding(1),
                    alignment: .bottom
                )
                .overlay(
                    Circle()
                        .stroke(Color.tallyAccent.opacity(0.32), lineWidth: 1)
                        .padding(-6)
                )
                .tallyShadow(.shadowFab)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1)
        .animation(.tallySpring, value: isPressed)
        .contentShape(Circle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
        .accessibilityLabel(Text("记一笔"))
    }
}

#Preview("TallyFAB Light") {
    TallyFAB {}
        .padding(40)
        .background(Color.tallyBg)
        .preferredColorScheme(.light)
}

#Preview("TallyFAB Dark") {
    TallyFAB {}
        .padding(40)
        .background(Color.tallyBg)
        .preferredColorScheme(.dark)
}
