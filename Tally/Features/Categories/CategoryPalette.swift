import SwiftUI

enum CategoryColorPalette {
    static let hexValues: [UInt32] = [
        0xB8553E,
        0xD6864A,
        0xC49A3C,
        0x7A8043,
        0x4D7148,
        0x5E8B7A,
        0x3D7D7E,
        0x5C6F86,
        0x5B5E8A,
        0x7E4D6E,
        0xA65566,
        0x6B6964
    ]

    static func defaultHex(for id: UUID) -> UInt32 {
        let bytes = Array(id.uuidString.utf8)
        let sum = bytes.reduce(0) { $0 + Int($1) }
        let index = abs(sum) % hexValues.count
        return hexValues[index]
    }

}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
