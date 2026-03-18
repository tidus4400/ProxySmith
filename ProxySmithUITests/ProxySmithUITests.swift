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
        confirmDeckDeletion(in: app)
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
        confirmDeckDeletion(in: app)

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
    func testCancelingDeckDeletionKeepsSelectedDeck() throws {
        let app = makeApp()
        app.terminateIfRunning()
        app.launch()
        app.activate()

        XCTAssertTrue(app.mainWindow.waitForExistence(timeout: 10))
        let window = libraryWindow(app)

        let deckNameField = app.textFields["deck-name-field"]
        let newDeckButton = window.buttons["sidebar-new-deck-button"]
        let toolbarDeleteButton = app.buttons["toolbar-delete-deck-button"].firstMatch

        XCTAssertTrue(newDeckButton.waitForExistence(timeout: 5))
        XCTAssertTrue(toolbarDeleteButton.waitForExistence(timeout: 5))

        newDeckButton.click()
        XCTAssertTrue(deckNameField.waitForExistence(timeout: 5))
        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 1")

        newDeckButton.click()
        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 2")

        toolbarDeleteButton.click()
        cancelDeckDeletion(in: app)

        XCTAssertEqual(deckNameField.currentStringValue, "Untitled Deck 2")
    }

    @MainActor
    func testUnsavedCacheFolderDraftResetsAfterClosingSettings() throws {
        let app = makeApp()
        assertUnsavedCacheFolderDraftResetsAfterClosingSettings(app: app) { app, settingsWindow in
            closeSettingsWindowUsingTitlebarButton(app: app, settingsWindow: settingsWindow)
        }
    }

    @MainActor
    func testUnsavedCacheFolderDraftResetsAfterCommandW() throws {
        let app = makeApp()
        assertUnsavedCacheFolderDraftResetsAfterClosingSettings(app: app) { app, _ in
            app.typeKey("w", modifierFlags: .command)
        }
    }

    @MainActor
    func testUnsavedCacheFolderDraftResetsAfterOutsideClick() throws {
        let app = makeApp()
        app.terminateIfRunning()
        app.launch()
        app.activate()

        let window = app.mainWindow
        XCTAssertTrue(window.waitForExistence(timeout: 10))

        let settingsButton = libraryWindow(app).buttons["sidebar-open-settings-button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.click()

        let cacheFolderField = app.textFields["card-image-cache-folder-field"]
        XCTAssertTrue(cacheFolderField.waitForExistence(timeout: 5))
        let originalValue = cacheFolderField.currentStringValue

        let savedFolderValue = app.staticTexts["card-image-cache-location-value"]
        XCTAssertTrue(savedFolderValue.waitForExistence(timeout: 5))
        XCTAssertEqual(savedFolderValue.currentStringValue, originalValue)

        cacheFolderField.click()
        app.typeKey("a", modifierFlags: .command)
        cacheFolderField.typeText("\(originalValue ?? "")-draft")

        XCTAssertEqual(cacheFolderField.currentStringValue, "\(originalValue ?? "")-draft")

        libraryWindow(app).coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.92)).click()
        XCTAssertTrue(waitForNonExistence(of: cacheFolderField))

        libraryWindow(app).buttons["sidebar-open-settings-button"].click()

        let reopenedCacheFolderField = app.textFields["card-image-cache-folder-field"]
        XCTAssertTrue(reopenedCacheFolderField.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedCacheFolderField.currentStringValue, originalValue)

        let reopenedSavedFolderValue = app.staticTexts["card-image-cache-location-value"]
        XCTAssertTrue(reopenedSavedFolderValue.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedSavedFolderValue.currentStringValue, originalValue)
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

    @MainActor
    private func assertUnsavedCacheFolderDraftResetsAfterClosingSettings(
        app: XCUIApplication,
        dismissSettings: (XCUIApplication, XCUIElement) -> Void
    ) {
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

        let savedFolderValue = app.staticTexts["card-image-cache-location-value"]
        XCTAssertTrue(savedFolderValue.waitForExistence(timeout: 5))
        XCTAssertEqual(savedFolderValue.currentStringValue, originalValue)

        cacheFolderField.click()
        app.typeKey("a", modifierFlags: .command)
        cacheFolderField.typeText("\(originalValue ?? "")-draft")

        XCTAssertEqual(cacheFolderField.currentStringValue, "\(originalValue ?? "")-draft")

        dismissSettings(app, settingsWindow(app))
        XCTAssertTrue(waitForNonExistence(of: cacheFolderField))

        settingsButton.click()

        let reopenedCacheFolderField = app.textFields["card-image-cache-folder-field"]
        XCTAssertTrue(reopenedCacheFolderField.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedCacheFolderField.currentStringValue, originalValue)

        let reopenedSavedFolderValue = app.staticTexts["card-image-cache-location-value"]
        XCTAssertTrue(reopenedSavedFolderValue.waitForExistence(timeout: 5))
        XCTAssertEqual(reopenedSavedFolderValue.currentStringValue, originalValue)
    }

    @MainActor
    private func settingsWindow(_ app: XCUIApplication) -> XCUIElement {
        for window in app.windows.allElementsBoundByIndex {
            let settingsRoot = window.descendants(matching: .any)["settings-root"]
            if settingsRoot.exists {
                return window
            }
        }

        XCTFail("Expected Settings window to exist")
        return app.windows.firstMatch
    }

    @MainActor
    private func closeSettingsWindowUsingTitlebarButton(
        app: XCUIApplication,
        settingsWindow: XCUIElement
    ) {
        let closeButton = settingsWindow.buttons["_XCUI:CloseWindow"]

        if closeButton.waitForExistence(timeout: 1) {
            closeButton.click()
            return
        }

        settingsWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.03)).click()
    }

    @MainActor
    private func libraryWindow(_ app: XCUIApplication) -> XCUIElement {
        for window in app.windows.allElementsBoundByIndex {
            let settingsButton = window.buttons["sidebar-open-settings-button"]
            if settingsButton.exists {
                return window
            }
        }

        XCTFail("Expected main library window to exist")
        return app.windows.firstMatch
    }

    @MainActor
    private func confirmDeckDeletion(in app: XCUIApplication) {
        let deleteConfirmation = app.sheets.firstMatch.buttons["Delete Deck"]
        XCTAssertTrue(deleteConfirmation.waitForExistence(timeout: 5))
        deleteConfirmation.click()
    }

    @MainActor
    private func cancelDeckDeletion(in app: XCUIApplication) {
        let cancelConfirmation = app.sheets.firstMatch.buttons["Cancel"]
        XCTAssertTrue(cancelConfirmation.waitForExistence(timeout: 5))
        cancelConfirmation.click()
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
