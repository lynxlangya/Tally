import XCTest
@testable import Tally

final class ProfileIdentityStoreTests: XCTestCase {
    func testDisplayNameFallsBackToTally() {
        XCTAssertEqual(ProfileIdentityStore.displayName(for: ""), "Tally")
        XCTAssertEqual(ProfileIdentityStore.displayName(for: "   "), "Tally")
    }

    func testDisplayNameTrimsStoredName() {
        XCTAssertEqual(ProfileIdentityStore.displayName(for: "  Yun  "), "Yun")
    }

    func testLimitedInputCapsNameLength() {
        let input = String(repeating: "A", count: ProfileIdentityStore.nameLimit + 4)
        XCTAssertEqual(ProfileIdentityStore.limitedInput(input).count, ProfileIdentityStore.nameLimit)
    }
}
