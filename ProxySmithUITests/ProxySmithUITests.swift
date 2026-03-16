import CoreGraphics
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

        let cachePeriodStepper = app.descendants(matching: .any)["card-image-cache-period-stepper"]
        XCTAssertTrue(waitForExistence(of: cachePeriodStepper))

        let cachePeriodValue = app.staticTexts["card-image-cache-period-value"]
        XCTAssertTrue(cachePeriodValue.waitForExistence(timeout: 5))
        XCTAssertEqual(cachePeriodValue.currentStringValue, "7 Days")

        let cacheFolderField = app.textFields["card-image-cache-folder-field"]
        XCTAssertTrue(cacheFolderField.waitForExistence(timeout: 5))
        cacheFolderField.click()
        app.typeKey("a", modifierFlags: .command)
        cacheFolderField.typeText("/tmp/proxysmith-ui-cache")

        let saveCacheFolderButton = app.buttons["save-card-image-cache-folder-button"]
        XCTAssertTrue(saveCacheFolderButton.waitForExistence(timeout: 5))
        saveCacheFolderButton.click()

        let saveCacheFolderConfirmation = app.sheets.firstMatch.buttons["Save"]
        XCTAssertTrue(saveCacheFolderConfirmation.waitForExistence(timeout: 5))
        saveCacheFolderConfirmation.click()

        XCTAssertEqual(cacheFolderField.currentStringValue, "/tmp/proxysmith-ui-cache")

        let cacheFolderValue = app.staticTexts["card-image-cache-location-value"]
        XCTAssertTrue(cacheFolderValue.waitForExistence(timeout: 5))
        XCTAssertEqual(cacheFolderValue.currentStringValue, "/tmp/proxysmith-ui-cache")

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
    func testUnsavedCacheFolderDraftResetsAfterClosingSettings() throws {
        let app = makeApp()
        app.terminateIfRunning()
        app.launch()
        app.activate()

        let window = app.mainWindow
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        let settingsButton = window.buttons["sidebar-open-settings-button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.click()

        let cacheFolderField = app.textFields["card-image-cache-folder-field"]
        XCTAssertTrue(cacheFolderField.waitForExistence(timeout: 5))
        let originalValue = cacheFolderField.currentStringValue

        cacheFolderField.click()
        app.typeKey("a", modifierFlags: .command)
        cacheFolderField.typeText("\(originalValue ?? "")-draft")

        XCTAssertEqual(cacheFolderField.currentStringValue, "\(originalValue ?? "")-draft")

        app.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(waitForNonExistence(of: cacheFolderField))

        settingsButton.click()

        let reopenedCacheFolderField = app.textFields["card-image-cache-folder-field"]
        XCTAssertTrue(reopenedCacheFolderField.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedCacheFolderField.currentStringValue, originalValue)
    }

    @MainActor
    func testAddCardsPopoverDismissesOnOutsideClick() throws {
        let app = makeApp()
        app.terminateIfRunning()
        app.launch()
        app.activate()

        let window = app.mainWindow
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        let newDeckButton = window.buttons["sidebar-new-deck-button"]
        XCTAssertTrue(newDeckButton.waitForExistence(timeout: 5))
        newDeckButton.click()

        let addCardsButton = window.buttons["deck-add-cards-button"]
        XCTAssertTrue(addCardsButton.waitForExistence(timeout: 5))
        addCardsButton.click()

        let searchField = app.textFields["card-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        let outsideClickTarget = window.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.20))
        outsideClickTarget.click()

        XCTAssertTrue(waitForNonExistence(of: searchField))
    }

    @MainActor
    func testDeckCardPreviewTogglesClosedOnSecondThumbnailClick() throws {
        let app = makeApp(extraLaunchArguments: ["--uitesting-seed-sample-deck"])
        app.terminateIfRunning()
        app.launch()
        app.activate()

        let window = app.mainWindow
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        let previewRow = app.descendants(matching: .any)["deck-card-row-ui-goblin-sharpshooter"]
        XCTAssertTrue(previewRow.waitForExistence(timeout: 10))

        let previewButton = previewRow.descendants(matching: .any)["deck-card-preview-button-ui-goblin-sharpshooter"]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 5))

        let previewPopovers = app.popovers
        XCTAssertTrue(waitForCount(of: previewPopovers, toBe: 0))

        previewButton.click()
        XCTAssertTrue(waitForCount(of: previewPopovers, toBe: 1))

        previewButton.click()
        XCTAssertTrue(waitForCount(of: previewPopovers, toBe: 0))
    }

    @MainActor
    private func makeApp(extraLaunchArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--uitesting-reset-state",
            "-ApplePersistenceIgnoreState",
            "YES",
            "-NSQuitAlwaysKeepsWindows",
            "NO"
        ] + extraLaunchArguments
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

private func waitForNonExistence(
    of element: XCUIElement,
    timeout: TimeInterval = 5
) -> Bool {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
}

private func waitForCount(
    of query: XCUIElementQuery,
    toBe expectedCount: Int,
    timeout: TimeInterval = 5
) -> Bool {
    let predicate = NSPredicate(format: "count == %d", expectedCount)
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: query)
    return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
}
