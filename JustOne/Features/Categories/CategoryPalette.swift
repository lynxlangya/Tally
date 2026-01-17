import SwiftUI

enum CategoryColorPalette {
    static let hexValues: [UInt32] = [
        0x13EC37,
        0x3B82F6,
        0xEF4444,
        0xEAB308,
        0xA855F7,
        0xF97316,
        0xEC4899,
        0x06B6D4,
        0x8B5CF6,
        0x14B8A6,
        0xF43F5E,
        0x22C55E,
        0x38BDF8,
        0x6366F1,
        0xF472B6
    ]

    static func defaultHex(for id: UUID) -> UInt32 {
        let bytes = Array(id.uuidString.utf8)
        let sum = bytes.reduce(0) { $0 + Int($1) }
        let index = abs(sum) % hexValues.count
        return hexValues[index]
    }

    static func randomHex() -> UInt32 {
        let hue = Double.random(in: 0...1)
        let saturation = Double.random(in: 0.55...0.85)
        let brightness = Double.random(in: 0.75...0.95)

        let (r, g, b) = hsbToRGB(hue: hue, saturation: saturation, brightness: brightness)
        let red = UInt32((r * 255).rounded())
        let green = UInt32((g * 255).rounded())
        let blue = UInt32((b * 255).rounded())
        return (red << 16) | (green << 8) | blue
    }

    private static func hsbToRGB(hue: Double, saturation: Double, brightness: Double) -> (Double, Double, Double) {
        let h = hue * 6
        let c = brightness * saturation
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c

        let (r1, g1, b1): (Double, Double, Double)
        switch h {
        case 0..<1: (r1, g1, b1) = (c, x, 0)
        case 1..<2: (r1, g1, b1) = (x, c, 0)
        case 2..<3: (r1, g1, b1) = (0, c, x)
        case 3..<4: (r1, g1, b1) = (0, x, c)
        case 4..<5: (r1, g1, b1) = (x, 0, c)
        default: (r1, g1, b1) = (c, 0, x)
        }

        return (r1 + m, g1 + m, b1 + m)
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
