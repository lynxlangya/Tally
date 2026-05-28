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
        // MARK: Food & Drink
        static let forkKnife = "fork-knife"
        static let coffee = "coffee"
        static let bowlFood = "bowl-food"
        static let hamburger = "hamburger"
        static let pizza = "pizza"
        static let wine = "wine"
        static let beerStein = "beer-stein"
        static let iceCream = "ice-cream"
        static let cookingPot = "cooking-pot"
        static let cake = "cake"
        static let cookie = "cookie"

        // MARK: Shopping
        static let shoppingCart = "shopping-cart"
        static let shoppingBag = "shopping-bag"
        static let handbag = "handbag"
        static let tag = "tag"
        static let storefront = "storefront"
        static let receipt = "receipt"

        // MARK: Home & Utilities
        static let house = "house"
        static let couch = "couch"
        static let bed = "bed"
        static let lightbulb = "lightbulb"
        static let lightning = "lightning"
        static let drop = "drop"
        static let flame = "flame"
        static let trash = "trash"
        static let wrench = "wrench"

        // MARK: Transport
        static let car = "car"
        static let bus = "bus"
        static let train = "train"
        static let airplaneTilt = "airplane-tilt"
        static let gasPump = "gas-pump"
        static let bicycle = "bicycle"
        static let motorcycle = "motorcycle"
        static let taxi = "taxi"
        static let mapPin = "map-pin"

        // MARK: Health
        static let firstAidKit = "first-aid-kit"
        static let pill = "pill"
        static let heartbeat = "heartbeat"
        static let syringe = "syringe"
        static let tooth = "tooth"
        static let stethoscope = "stethoscope"

        // MARK: Education
        static let graduationCap = "graduation-cap"
        static let bookOpen = "book-open"
        static let books = "books"
        static let notebook = "notebook"
        static let pencil = "pencil"

        // MARK: Entertainment
        static let filmSlate = "film-slate"
        static let musicNotes = "music-notes"
        static let gameController = "game-controller"
        static let popcorn = "popcorn"
        static let television = "television"
        static let headphones = "headphones"
        static let ticket = "ticket"
        static let camera = "camera"

        // MARK: Fitness
        static let barbell = "barbell"
        static let personSimpleRun = "person-simple-run"
        static let soccerBall = "soccer-ball"
        static let basketball = "basketball"
        static let sneakerMove = "sneaker-move"

        // MARK: Tech & Comm
        static let wifiHigh = "wifi-high"
        static let phone = "phone"
        static let deviceMobile = "device-mobile"
        static let laptop = "laptop"
        static let cloud = "cloud"

        // MARK: Clothing & Beauty
        static let tShirt = "t-shirt"
        static let pants = "pants"
        static let dress = "dress"
        static let eyeglasses = "eyeglasses"
        static let scissors = "scissors"

        // MARK: Pets
        static let pawPrint = "paw-print"
        static let dog = "dog"
        static let cat = "cat"

        // MARK: Travel
        static let suitcaseRolling = "suitcase-rolling"
        static let mountains = "mountains"
        static let tent = "tent"
        static let globeHemisphereWest = "globe-hemisphere-west"

        // MARK: Social
        static let heart = "heart"
        static let handHeart = "hand-heart"
        static let usersThree = "users-three"
        static let baby = "baby"
        static let gift = "gift"

        // MARK: Income & Finance
        static let briefcase = "briefcase"
        static let moneyWavy = "money-wavy"
        static let bank = "bank"
        static let coins = "coins"
        static let creditCard = "credit-card"
        static let wallet = "wallet"
        static let currencyCny = "currency-cny"

        // MARK: Utility
        static let repeatIcon = "repeat"
        static let fileText = "file-text"
        static let leaf = "leaf"
        static let gearSix = "gear-six"
        static let bell = "bell"
        static let globe = "globe"
        static let magnifyingGlass = "magnifying-glass"
        static let info = "info"

        static let all: [String] = [
            forkKnife,
            coffee,
            bowlFood,
            hamburger,
            pizza,
            wine,
            beerStein,
            iceCream,
            cookingPot,
            cake,
            cookie,
            shoppingCart,
            shoppingBag,
            handbag,
            tag,
            storefront,
            receipt,
            house,
            couch,
            bed,
            lightbulb,
            lightning,
            drop,
            flame,
            trash,
            wrench,
            car,
            bus,
            train,
            airplaneTilt,
            gasPump,
            bicycle,
            motorcycle,
            taxi,
            mapPin,
            firstAidKit,
            pill,
            heartbeat,
            syringe,
            tooth,
            stethoscope,
            graduationCap,
            bookOpen,
            books,
            notebook,
            pencil,
            filmSlate,
            musicNotes,
            gameController,
            popcorn,
            television,
            headphones,
            ticket,
            camera,
            barbell,
            personSimpleRun,
            soccerBall,
            basketball,
            sneakerMove,
            wifiHigh,
            phone,
            deviceMobile,
            laptop,
            cloud,
            tShirt,
            pants,
            dress,
            eyeglasses,
            scissors,
            pawPrint,
            dog,
            cat,
            suitcaseRolling,
            mountains,
            tent,
            globeHemisphereWest,
            heart,
            handHeart,
            usersThree,
            baby,
            gift,
            briefcase,
            moneyWavy,
            bank,
            coins,
            creditCard,
            wallet,
            currencyCny
        ]

        static let utility: [String] = [
            repeatIcon,
            fileText,
            leaf,
            gearSix,
            bell,
            globe,
            magnifyingGlass,
            info
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
