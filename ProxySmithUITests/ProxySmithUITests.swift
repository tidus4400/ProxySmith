import XCTest

final class ProxySmithUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testGlobalDeckNumberingSkipsDeletedValues() throws {
        let app = makeApp()
        app.terminateIfRunning()
        app.launch()
        app.activate()

        let window = app.mainWindow
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        let deckNameField = app.textFields["deck-name-field"]
        let newDeckButton = window.buttons["sidebar-new-deck-button"]
        let deleteDeckButton = window.buttons["sidebar-delete-deck-button"]

        XCTAssertTrue(newDeckButton.waitForExistence(timeout: 5))
        XCTAssertTrue(deleteDeckButton.waitForExistence(timeout: 5))

        newDeckButton.click()
        XCTAssertTrue(deckNameField.waitForExistence(timeout: 5))
        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 1")

        newDeckButton.click()
        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 2")

        newDeckButton.click()
        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 3")

        deleteDeckButton.click()
        newDeckButton.click()

        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 4")
    }

    @MainActor
    func testSettingsCanDisableGlobalNumberingAndResetCounter() throws {
        let app = makeApp()
        app.terminateIfRunning()
        app.launch()
        app.activate()

        let window = app.mainWindow
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        let deckNameField = app.textFields["deck-name-field"]
        let newDeckButton = window.buttons["sidebar-new-deck-button"]
        let deleteDeckButton = window.buttons["sidebar-delete-deck-button"]

        XCTAssertTrue(newDeckButton.waitForExistence(timeout: 5))

        newDeckButton.click()
        newDeckButton.click()
        newDeckButton.click()
        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 3")

        deleteDeckButton.click()

        let settingsButton = window.buttons["sidebar-open-settings-button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.click()

        let numberingToggle = app.switches["global-deck-numbering-toggle"]
        XCTAssertTrue(waitForExistence(of: numberingToggle))
        numberingToggle.click()

        let resetButton = app.buttons["reset-deck-counter-button"]
        XCTAssertTrue(waitForExistence(of: resetButton))
        resetButton.click()

        let resetConfirmation = app.sheets.firstMatch.buttons["Reset"]
        XCTAssertTrue(resetConfirmation.waitForExistence(timeout: 5))
        resetConfirmation.click()

        let nextNumberValue = app.staticTexts["next-global-deck-number-value"]
        XCTAssertTrue(nextNumberValue.waitForExistence(timeout: 5))
        XCTAssertEqual(nextNumberValue.currentStringValue, "3")

        app.typeKey("w", modifierFlags: .command)

        newDeckButton.click()
        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 3")
    }

    @MainActor
    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--uitesting-reset-state",
            "-ApplePersistenceIgnoreState",
            "YES",
            "-NSQuitAlwaysKeepsWindows",
            "NO"
        ]
        return app
    }
}

private extension XCUIElement {
    var currentStringValue: String? {
        (value as? String) ?? label
    }
}

private extension XCUIApplication {
    var mainWindow: XCUIElement {
        windows.firstMatch
    }

    func terminateIfRunning() {
        if state != .notRunning {
            terminate()
        }
    }
}

@MainActor
private func waitForExistence(
    of element: XCUIElement,
    timeout: TimeInterval = 5
) -> Bool {
    element.waitForExistence(timeout: timeout)
}
