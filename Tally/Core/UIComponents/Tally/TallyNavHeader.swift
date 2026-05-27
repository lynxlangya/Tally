import SwiftUI

struct TallyNavHeader: View {
    let title: String
    let onBack: (() -> Void)?
    let trailing: AnyView?
    let eyebrow: String?

    init(
        title: String,
        onBack: (() -> Void)? = nil,
        trailing: AnyView? = nil,
        eyebrow: String? = nil
    ) {
        self.title = title
        self.onBack = onBack
        self.trailing = trailing
        self.eyebrow = eyebrow
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            leadingSlot
                .frame(width: 36, height: 36)

            VStack(spacing: 2) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(TallyType.display(10, weight: .semibold))
                        .tracking(10 * 0.12)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.tallyInkFaint)
                        .lineLimit(1)
                }

                Text(title)
                    .font(TallyType.display(17, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            trailingSlot
                .frame(width: 36, height: 36)
        }
        .padding(EdgeInsets(top: 8, leading: 20, bottom: 12, trailing: 20))
        .frame(minHeight: 48)
    }

    @ViewBuilder
    private var leadingSlot: some View {
        if let onBack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.tallyInk)
                    .frame(width: 36, height: 36)
                    .background(Color.tallySurface2)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("返回"))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var trailingSlot: some View {
        if let trailing {
            trailing
        } else {
            Color.clear
        }
    }
}

#Preview("TallyNavHeader Light") {
    VStack(spacing: TallySpacing.s5) {
        TallyNavHeader(title: "账本", onBack: {})
        TallyNavHeader(
            title: "类别",
            onBack: {},
            trailing: AnyView(Image(systemName: "plus").foregroundStyle(Color.tallyAccent)),
            eyebrow: "settings"
        )
    }
    .padding()
    .background(Color.tallyBg)
    .preferredColorScheme(.light)
}

#Preview("TallyNavHeader Dark") {
    VStack(spacing: TallySpacing.s5) {
        TallyNavHeader(title: "账本", onBack: {})
        TallyNavHeader(
            title: "类别",
            onBack: {},
            trailing: AnyView(Image(systemName: "plus").foregroundStyle(Color.tallyAccent)),
            eyebrow: "settings"
        )
    }
    .padding()
    .background(Color.tallyBg)
    .preferredColorScheme(.dark)
}
