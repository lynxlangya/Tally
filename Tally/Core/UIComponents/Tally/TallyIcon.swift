import SwiftUI
import UIKit

struct TallyIcon: View {
    let name: String
    var size: CGFloat = 20

    var body: some View {
        if UIImage(named: name) != nil {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: name)
                .font(.system(size: size * 0.9, weight: .regular))
                .frame(width: size, height: size)
        }
    }
}

extension TallyIcon {
    enum Catalog {
        static let forkKnife = "fork.knife"
        static let cupAndSaucerFill = "cup.and.saucer.fill"
        static let cartFill = "cart.fill"
        static let bagFill = "bag.fill"
        static let houseFill = "house.fill"
        static let lightbulbFill = "lightbulb.fill"
        static let dropFill = "drop.fill"
        static let crossCaseFill = "cross.case.fill"
        static let pillsFill = "pills.fill"
        static let graduationcapFill = "graduationcap.fill"
        static let bookFill = "book.fill"
        static let carFill = "car.fill"
        static let tramFill = "tram.fill"
        static let airplane = "airplane"
        static let fuelpumpFill = "fuelpump.fill"
        static let cupAndHeatWavesFill = "cup.and.heat.waves.fill"
        static let birthdayCakeFill = "birthday.cake.fill"
        static let banknoteFill = "banknote.fill"
        static let creditcardFill = "creditcard.fill"
        static let briefcaseFill = "briefcase.fill"
        static let dumbbellFill = "dumbbell.fill"
        static let figureWalk = "figure.walk"
        static let giftFill = "gift.fill"
        static let film = "film"
        static let musicNote = "music.note"
        static let pawprintFill = "pawprint.fill"
        static let leafFill = "leaf.fill"
        static let wifi = "wifi"
        static let phoneFill = "phone.fill"
        static let calendar = "calendar"
        static let repeatIcon = "repeat"
        static let tshirtFill = "tshirt.fill"
        static let scissors = "scissors"
        static let gamecontrollerFill = "gamecontroller.fill"
        static let docTextFill = "doc.text.fill"

        static let all: [String] = [
            forkKnife,
            cupAndSaucerFill,
            cartFill,
            bagFill,
            houseFill,
            lightbulbFill,
            dropFill,
            crossCaseFill,
            pillsFill,
            graduationcapFill,
            bookFill,
            carFill,
            tramFill,
            airplane,
            fuelpumpFill,
            cupAndHeatWavesFill,
            birthdayCakeFill,
            banknoteFill,
            creditcardFill,
            briefcaseFill,
            dumbbellFill,
            figureWalk,
            giftFill,
            film,
            musicNote,
            pawprintFill,
            leafFill,
            wifi,
            phoneFill,
            calendar,
            repeatIcon,
            tshirtFill,
            scissors,
            gamecontrollerFill,
            docTextFill
        ]
    }
}

#Preview("TallyIcon Gallery Light") {
    TallyIconGalleryPreview()
        .preferredColorScheme(.light)
}

#Preview("TallyIcon Gallery Dark") {
    TallyIconGalleryPreview()
        .preferredColorScheme(.dark)
}

private struct TallyIconGalleryPreview: View {
    private let columns = [
        GridItem(.adaptive(minimum: 54), spacing: TallySpacing.s3)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: TallySpacing.s4) {
                ForEach(TallyIcon.Catalog.all, id: \.self) { name in
                    VStack(spacing: TallySpacing.s2) {
                        TallyIcon(name: name, size: 22)
                            .foregroundStyle(Color.tallyAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.tallyAccentTint)
                            .clipShape(RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous))
                        Text(name)
                            .font(TallyType.body(9, weight: .medium))
                            .foregroundStyle(Color.tallyInkDim)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                }

                TallyIcon(name: "no.such.icon", size: 22)
                    .foregroundStyle(Color.tallyInkDim)
                    .frame(width: 44, height: 44)
                    .background(Color.tallySurface2)
                    .clipShape(RoundedRectangle(cornerRadius: TallyRadii.md, style: .continuous))
            }
            .padding(TallySpacing.s6)
        }
        .background(Color.tallyBg)
    }
}
