import Foundation
import Testing
@testable import ProxySmith

struct ScryfallCardTests {
    @Test
    func prefersPrimaryImageUrisBeforeFaceFallback() {
        let card = ScryfallCard(
            id: "1",
            name: "Test Card",
            set: "tst",
            setName: "Test Set",
            collectorNumber: "12",
            manaCost: "{1}{U}",
            typeLine: "Creature",
            rarity: "rare",
            imageUris: .init(
                png: URL(string: "https://example.com/print.png"),
                large: URL(string: "https://example.com/large.jpg"),
                normal: URL(string: "https://example.com/normal.jpg"),
                small: URL(string: "https://example.com/small.jpg")
            ),
            cardFaces: [
                .init(
                    name: "Face",
                    manaCost: "{U}",
                    typeLine: "Creature",
                    imageUris: .init(
                        png: URL(string: "https://example.com/face-print.png"),
                        large: nil,
                        normal: nil,
                        small: nil
                    )
                )
            ]
        )

        #expect(card.previewImageURL?.absoluteString == "https://example.com/small.jpg")
        #expect(card.printImageURL?.absoluteString == "https://example.com/print.png")
    }

    @Test
    func fallsBackToFrontFaceDataForSplitLayouts() {
        let card = ScryfallCard(
            id: "2",
            name: "Split Test",
            set: "tst",
            setName: "Test Set",
            collectorNumber: "99",
            manaCost: nil,
            typeLine: nil,
            rarity: "mythic",
            imageUris: nil,
            cardFaces: [
                .init(
                    name: "Front Face",
                    manaCost: "{2}{R}",
                    typeLine: "Sorcery",
                    imageUris: .init(
                        png: URL(string: "https://example.com/front.png"),
                        large: URL(string: "https://example.com/front-large.jpg"),
                        normal: URL(string: "https://example.com/front-normal.jpg"),
                        small: URL(string: "https://example.com/front-small.jpg")
                    )
                )
            ]
        )

        #expect(card.displayName == "Front Face")
        #expect(card.displayManaCost == "{2}{R}")
        #expect(card.displayTypeLine == "Sorcery")
        #expect(card.previewImageURL?.absoluteString == "https://example.com/front-small.jpg")
        #expect(card.printImageURL?.absoluteString == "https://example.com/front.png")
    }

    @Test
    func deckCardCarriesNormalizedBorderColorIntoExportCard() {
        let scryfallCard = ScryfallCard(
            id: "3",
            name: "Golden Proxy",
            set: "tst",
            setName: "Test Set",
            collectorNumber: "7",
            manaCost: "{3}",
            typeLine: "Artifact",
            rarity: "rare",
            borderColor: "GoLd",
            imageUris: nil,
            cardFaces: nil
        )

        let deckCard = DeckCard(scryfallCard: scryfallCard)

        #expect(deckCard.borderColorName == "gold")
        #expect(deckCard.exportCard.borderColorName == "gold")
    }
}
