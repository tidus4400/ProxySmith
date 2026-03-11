import Foundation
import SwiftData

@Model
final class DeckCard {
    var id: UUID
    var scryfallID: String
    var name: String
    var manaCost: String
    var typeLine: String
    var setCode: String
    var setName: String
    var collectorNumber: String
    var rarity: String
    var quantity: Int
    var previewImageURLString: String
    var printImageURLString: String
    var addedAt: Date
    var deck: Deck?

    init(
        id: UUID = UUID(),
        scryfallID: String,
        name: String,
        manaCost: String,
        typeLine: String,
        setCode: String,
        setName: String,
        collectorNumber: String,
        rarity: String,
        quantity: Int = 1,
        previewImageURLString: String,
        printImageURLString: String,
        addedAt: Date = .now,
        deck: Deck? = nil
    ) {
        self.id = id
        self.scryfallID = scryfallID
        self.name = name
        self.manaCost = manaCost
        self.typeLine = typeLine
        self.setCode = setCode
        self.setName = setName
        self.collectorNumber = collectorNumber
        self.rarity = rarity
        self.quantity = quantity
        self.previewImageURLString = previewImageURLString
        self.printImageURLString = printImageURLString
        self.addedAt = addedAt
        self.deck = deck
    }

    convenience init(scryfallCard: ScryfallCard, deck: Deck? = nil) {
        self.init(
            scryfallID: scryfallCard.id,
            name: scryfallCard.displayName,
            manaCost: scryfallCard.displayManaCost,
            typeLine: scryfallCard.displayTypeLine,
            setCode: scryfallCard.set.uppercased(),
            setName: scryfallCard.setName,
            collectorNumber: scryfallCard.collectorNumber,
            rarity: scryfallCard.rarity.capitalized,
            previewImageURLString: scryfallCard.previewImageURL?.absoluteString ?? "",
            printImageURLString: scryfallCard.printImageURL?.absoluteString ?? "",
            deck: deck
        )
    }

    var previewImageURL: URL? {
        URL(string: previewImageURLString)
    }

    var printImageURL: URL? {
        URL(string: printImageURLString)
    }

    var setLine: String {
        "\(setCode) • \(collectorNumber) • \(rarity)"
    }

    var exportCard: DeckExportCard {
        DeckExportCard(name: name, imageURL: printImageURL ?? previewImageURL, quantity: quantity)
    }
}

