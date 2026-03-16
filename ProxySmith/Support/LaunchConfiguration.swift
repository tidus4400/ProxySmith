import Foundation
import SwiftData

enum LaunchConfiguration {
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
    static let shouldResetState = ProcessInfo.processInfo.arguments.contains("--uitesting-reset-state")
    static let shouldSeedSampleDeck = ProcessInfo.processInfo.arguments.contains("--uitesting-seed-sample-deck")
    static let isRunningAutomatedTests =
        isUITesting || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    static func makeModelConfiguration() -> ModelConfiguration {
        ModelConfiguration(isStoredInMemoryOnly: isUITesting)
    }

    static func makeStorageLayout(fileManager: FileManager = .default) -> ProxySmithStorageLayout {
        if isUITesting {
            let rootDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent("ProxySmith-UITests", isDirectory: true)

            if shouldResetState {
                try? fileManager.removeItem(at: rootDirectory)
            }

            return ProxySmithStorageLayout(rootDirectory: rootDirectory)
        }

        return ProxySmithStorageLayout(
            rootDirectory: fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".proxysmith", isDirectory: true)
        )
    }

    static func makeImageCacheStorage(
        storageLayout: ProxySmithStorageLayout? = nil
    ) -> CardImageRepository.Storage {
        if isRunningAutomatedTests {
            return .memory
        }

        let resolvedStorageLayout = storageLayout ?? makeStorageLayout()
        return .disk(resolvedStorageLayout.cardImageCacheDirectory)
    }

    static func makeUITestSampleDeck() -> Deck {
        let deck = Deck(name: "UITest Sample Deck")
        let goblinFixtureURL = uiTestFixtureURL(named: "goblin-sharpshooter.png")
        let serraFixtureURL = uiTestFixtureURL(named: "serra-angel.png")

        deck.cards.append(makeUITestCard(
            scryfallID: "ui-goblin-sharpshooter",
            name: "Goblin Sharpshooter",
            manaCost: "{2}{R}",
            typeLine: "Creature — Goblin",
            setCode: "ONS",
            setName: "Onslaught",
            collectorNumber: "206",
            rarity: "Rare",
            quantity: 2,
            previewImageURLString: goblinFixtureURL.absoluteString,
            printImageURLString: goblinFixtureURL.absoluteString
        ))

        deck.cards.append(makeUITestCard(
            scryfallID: "ui-serra-angel",
            name: "Serra Angel",
            manaCost: "{3}{W}{W}",
            typeLine: "Creature — Angel",
            setCode: "FDN",
            setName: "Foundations",
            collectorNumber: "30",
            rarity: "Uncommon",
            quantity: 1,
            previewImageURLString: serraFixtureURL.absoluteString,
            printImageURLString: serraFixtureURL.absoluteString
        ))

        return deck
    }

    private static func makeUITestCard(
        scryfallID: String,
        name: String,
        manaCost: String,
        typeLine: String,
        setCode: String,
        setName: String,
        collectorNumber: String,
        rarity: String,
        quantity: Int,
        previewImageURLString: String,
        printImageURLString: String
    ) -> DeckCard {
        DeckCard(
            scryfallID: scryfallID,
            name: name,
            manaCost: manaCost,
            typeLine: typeLine,
            setCode: setCode,
            setName: setName,
            collectorNumber: collectorNumber,
            rarity: rarity,
            quantity: quantity,
            previewImageURLString: previewImageURLString,
            printImageURLString: printImageURLString
        )
    }

    private static func uiTestFixtureURL(named filename: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestAssets/CardPreviewFixtures")
            .appendingPathComponent(filename)
    }
}
