import Testing
@testable import ProxySmith

struct DeckNameGeneratorTests {
    @Test
    func globalNumberingNeverReusesDeletedGaps() {
        let generation = DeckNameGenerator.nextName(
            existingNames: ["Untitled Deck 1", "Untitled Deck 2", "Untitled Deck 4"],
            globalNumberingEnabled: true,
            storedNextGlobalDeckNumber: 3
        )

        #expect(generation.name == "Untitled Deck 5")
        #expect(generation.updatedNextGlobalDeckNumber == 6)
    }

    @Test
    func reusableNumberingFillsLowestMissingNumber() {
        let generation = DeckNameGenerator.nextName(
            existingNames: ["Untitled Deck 1", "Untitled Deck 3"],
            globalNumberingEnabled: false,
            storedNextGlobalDeckNumber: 9
        )

        #expect(generation.name == "Untitled Deck 2")
        #expect(generation.updatedNextGlobalDeckNumber == 9)
    }

    @Test
    func legacyUntitledDeckNameStillReservesNumberOne() {
        #expect(DeckNameGenerator.extractDeckNumber(from: "Untitled Deck") == 1)
        #expect(DeckNameGenerator.nextReusableDeckNumber(existingNames: ["Untitled Deck", "Untitled Deck 2"]) == 3)
    }

    @Test
    func resetCounterStillHonorsHighestExistingDeckNumber() {
        let nextDeckNumber = DeckNameGenerator.nextGlobalDeckNumber(
            existingNames: ["Untitled Deck 2", "Untitled Deck 7"],
            storedNextGlobalDeckNumber: 1
        )

        #expect(nextDeckNumber == 8)
    }
}

