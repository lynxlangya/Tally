import SwiftUI

extension Animation {
    static let tallyFast = Animation.easeOut(duration: 0.12)
    static let tallyBase = Animation.easeOut(duration: 0.22)
    static let tallyEmph = Animation.easeOut(duration: 0.36)
    static let tallySpring = Animation.spring(response: 0.36, dampingFraction: 0.62)
}
