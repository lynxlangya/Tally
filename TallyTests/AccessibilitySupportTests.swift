import UIKit
import XCTest
@testable import Tally

final class AccessibilitySupportTests: XCTestCase {
    func testTallyTypeScalesPointSizeForAccessibilityContentSize() {
        let baseSize: CGFloat = 17
        let scaledSize = TallyType.scaledPointSizeForTesting(
            baseSize,
            contentSizeCategory: .accessibilityMedium
        )

        XCTAssertGreaterThan(scaledSize, baseSize)
    }
}
