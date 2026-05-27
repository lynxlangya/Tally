import SwiftUI

struct Segmented<Value: Hashable>: View {
    enum Size {
        case sm
        case md
        case lg

        var fontSize: CGFloat {
            switch self {
            case .sm: return 12
            case .md: return 13
            case .lg: return 15
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .sm: return 12
            case .md: return 14
            case .lg: return 20
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .sm: return 6
            case .md: return 8
            case .lg: return 12
            }
        }
    }

    @Binding var value: Value
    let options: [(Value, String)]
    let size: Size

    init(value: Binding<Value>, options: [(Value, String)], size: Size = .md) {
        self._value = value
        self.options = options
        self.size = size
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.0) { option in
                let active = option.0 == value
                Button {
                    withAnimation(.tallyFast) {
                        value = option.0
                    }
                } label: {
                    Text(option.1)
                        .font(TallyType.body(size.fontSize, weight: .medium))
                        .foregroundStyle(active ? Color.tallyAccentInk : Color.tallyInkDim)
                        .padding(.horizontal, size.horizontalPadding)
                        .padding(.vertical, size.verticalPadding)
                        .frame(minWidth: 44)
                        .background(active ? Color.tallyAccent : Color.clear)
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.tallySurface)
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.tallyLine, lineWidth: 0.5)
        )
    }
}

#Preview("Segmented Light") {
    SegmentedPreview()
        .preferredColorScheme(.light)
}

#Preview("Segmented Dark") {
    SegmentedPreview()
        .preferredColorScheme(.dark)
}

private struct SegmentedPreview: View {
    @State private var value = "expense"

    var body: some View {
        VStack(spacing: TallySpacing.s4) {
            Segmented(value: $value, options: [("expense", "支出"), ("income", "收入")], size: .sm)
            Segmented(value: $value, options: [("expense", "支出"), ("income", "收入")], size: .md)
            Segmented(value: $value, options: [("expense", "支出"), ("income", "收入")], size: .lg)
        }
        .padding()
        .background(Color.tallyBg)
    }
}
