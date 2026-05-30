import SwiftUI
import UIKit

struct ProfileAvatarView: View {
    let avatarData: Data
    let size: CGFloat
    let cornerRadius: CGFloat
    let appIcon: ThemeAppIconOption
    let accent: Color
    var showsEditBadge: Bool = false

    private var avatarImage: UIImage? {
        guard !avatarData.isEmpty else { return nil }
        return UIImage(data: avatarData)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarContent
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.tallyLineHi, lineWidth: 0.6)
                )

            if showsEditBadge {
                Image(systemName: "pencil")
                    .font(.system(size: max(10, size * 0.15), weight: .bold))
                    .foregroundStyle(Color.tallyAccentInk)
                    .frame(width: max(22, size * 0.31), height: max(22, size * 0.31))
                    .background(accent)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.tallyBg, lineWidth: 2))
                    .offset(x: size * 0.06, y: size * 0.06)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let avatarImage {
            Image(uiImage: avatarImage)
                .resizable()
                .scaledToFill()
        } else {
            AppIconAvatar(option: appIcon, accent: accent)
        }
    }
}

private struct AppIconAvatar: View {
    let option: ThemeAppIconOption
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            let length = min(proxy.size.width, proxy.size.height)
            icon
                .frame(width: proxy.size.width, height: proxy.size.height)
                .overlay(
                    TallyMark(
                        size: markSize(for: length),
                        variant: markVariant,
                        color: markColor,
                        strokeWidth: strokeWidth(for: length)
                    )
                )
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch option {
        case .vermilion:
            Rectangle()
                .fill(accent)
        case .moon:
            Rectangle()
                .fill(Color.tallySurface)
        case .ink, .inkNote:
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.tallyInk, Color.tallyInk.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .bottomTrailing) {
                    if option == .inkNote {
                        Text("记")
                            .font(TallyType.body(10, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(accent)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .padding(5)
                    }
                }
        }
    }

    private var markVariant: TallyMark.Variant {
        option == .ink ? .one : .five
    }

    private var markColor: Color {
        switch option {
        case .vermilion:
            return .white
        case .moon, .inkNote:
            return accent
        case .ink:
            return .white
        }
    }

    private func markSize(for length: CGFloat) -> CGFloat {
        switch option {
        case .ink:
            return length * 0.47
        default:
            return length * 0.53
        }
    }

    private func strokeWidth(for length: CGFloat) -> CGFloat {
        max(2.2, length * 0.047)
    }
}
