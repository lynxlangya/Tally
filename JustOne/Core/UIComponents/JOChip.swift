import SwiftUI

struct JOChip: View {
    let text: String
    let isEmphasized: Bool

    init(_ text: String, isEmphasized: Bool = false) {
        self.text = text
        self.isEmphasized = isEmphasized
    }

    var body: some View {
        Text(text)
            .font(JOTypography.caption)
            .foregroundStyle(isEmphasized ? JOColors.accentForeground : JOColors.textSecondary)
            .padding(.horizontal, JOSpacing.md)
            .padding(.vertical, JOSpacing.xs)
            .background(isEmphasized ? JOColors.accent : JOColors.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(JOColors.divider, lineWidth: isEmphasized ? 0 : 1))
    }
}
