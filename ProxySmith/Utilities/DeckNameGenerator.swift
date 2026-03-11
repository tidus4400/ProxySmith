import Foundation

struct DeckNameGeneration: Equatable {
    let name: String
    let updatedNextGlobalDeckNumber: Int
}

enum DeckNameGenerator {
    static let baseName = "Untitled Deck"

    static func nextName(
        existingNames: [String],
        globalNumberingEnabled: Bool,
        storedNextGlobalDeckNumber: Int
    ) -> DeckNameGeneration {
        if globalNumberingEnabled {
            let deckNumber = nextGlobalDeckNumber(
                existingNames: existingNames,
                storedNextGlobalDeckNumber: storedNextGlobalDeckNumber
            )

            return DeckNameGeneration(
                name: name(for: deckNumber),
                updatedNextGlobalDeckNumber: deckNumber + 1
            )
        }

        return DeckNameGeneration(
            name: name(for: nextReusableDeckNumber(existingNames: existingNames)),
            updatedNextGlobalDeckNumber: max(storedNextGlobalDeckNumber, 1)
        )
    }

    static func nextGlobalDeckNumber(
        existingNames: [String],
        storedNextGlobalDeckNumber: Int
    ) -> Int {
        max(1, storedNextGlobalDeckNumber, highestReservedDeckNumber(existingNames: existingNames) + 1)
    }

    static func nextReusableDeckNumber(existingNames: [String]) -> Int {
        let reservedNumbers = Set(existingNames.compactMap(extractDeckNumber))
        var candidate = 1

        while reservedNumbers.contains(candidate) {
            candidate += 1
        }

        return candidate
    }

    static func highestReservedDeckNumber(existingNames: [String]) -> Int {
        existingNames.compactMap(extractDeckNumber).max() ?? 0
    }

    static func name(for deckNumber: Int) -> String {
        "\(baseName) \(max(deckNumber, 1))"
    }

    static func extractDeckNumber(from name: String) -> Int? {
        if name == baseName {
            return 1
        }

        let prefix = "\(baseName) "
        guard name.hasPrefix(prefix) else {
            return nil
        }

        return Int(name.dropFirst(prefix.count))
    }
}

