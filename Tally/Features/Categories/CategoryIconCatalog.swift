import Foundation

enum CategoryIconCatalog {
    static let icons: [String] = [
        "fork.knife", "cup.and.saucer.fill", "cup.and.heat.waves.fill", "birthday.cake.fill",
        "fish", "cart.fill", "bag.fill", "basket.fill",
        "bag.badge.plus", "house.fill", "lightbulb.fill", "cross.case.fill",
        "graduationcap.fill", "car.fill", "tram.fill", "airplane",
        "bus", "fuelpump.fill", "banknote.fill", "creditcard.fill",
        "wallet.pass.fill", "dollarsign.circle.fill", "briefcase.fill", "chart.line.uptrend.xyaxis",
        "percent", "dumbbell.fill", "gift.fill", "film",
        "pawprint.fill", "phone.fill", "envelope.fill", "repeat",
        "tshirt.fill", "gamecontroller.fill", "questionmark", "calendar"
    ]

    static var sheetIcons: [String] {
        Array(icons.prefix(36))
    }
}
