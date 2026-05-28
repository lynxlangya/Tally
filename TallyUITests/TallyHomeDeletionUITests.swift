import XCTest

final class TallyHomeDeletionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDeletesHomeBillFromContextMenu() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-tallyUsePreviewData"]
        app.launch()

        let billRow = app.buttons["示例账单 支出"].firstMatch
        XCTAssertTrue(billRow.waitForExistence(timeout: 5))

        billRow.press(forDuration: 1.0)

        let deleteMenuItem = app.buttons["删除"].firstMatch
        XCTAssertTrue(deleteMenuItem.waitForExistence(timeout: 3))
        deleteMenuItem.tap()

        let confirmDeleteButton = app.buttons["确定删除"].firstMatch
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 3))
        confirmDeleteButton.tap()

        XCTAssertFalse(billRow.waitForExistence(timeout: 2))
    }
}
