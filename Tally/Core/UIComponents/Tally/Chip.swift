import SwiftUI

struct Chip: View {
    enum Tone {
        case neutral
        case accent
        case outline
    }

    enum Size {
        case xs
        case sm

        var fontSize: CGFloat {
            switch self {
            case .xs: return 11
            case .sm: return 12
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .xs: return 8
            case .sm: return 10
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .xs: return 3
            case .sm: return 5
            }
        }
    }

    let text: String
    let tone: Tone
    let size: Size
    let icon: Image?

    init(_ text: String, tone: Tone = .neutral, size: Size = .sm, icon: Image? = nil) {
        self.text = text
        self.tone = tone
        self.size = size
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: TallySpacing.s1) {
            if let icon {
                icon
                    .font(.system(size: size.fontSize, weight: .medium))
            }
            Text(text)
                .font(TallyType.body(size.fontSize, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(backgroundColor)
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(borderColor, lineWidth: tone == .outline ? 0.5 : 0)
        )
    }

    private var foregroundColor: Color {
        switch tone {
        case .neutral, .outline:
            return .tallyInkDim
        case .accent:
            return .tallyAccent
        }
    }

    private var backgroundColor: Color {
        switch tone {
        case .neutral:
            return .tallySurface2
        case .accent:
            return .tallyAccentTint
        case .outline:
            return .clear
        }
    }

    private var borderColor: Color {
        switch tone {
        case .outline:
            return .tallyLineHi
        case .neutral, .accent:
            return .clear
        }
    }
}

#Preview("Chip Light") {
    ChipPreview()
        .preferredColorScheme(.light)
}

#Preview("Chip Dark") {
    ChipPreview()
        .preferredColorScheme(.dark)
}

private struct ChipPreview: View {
    var body: some View {
        HStack(spacing: TallySpacing.s3) {
            Chip("今天")
            Chip("收入", tone: .accent, icon: Image(systemName: "arrow.down"))
            Chip("筛选", tone: .outline, size: .xs)
        }
        .padding()
        .background(Color.tallyBg)
    }
}
