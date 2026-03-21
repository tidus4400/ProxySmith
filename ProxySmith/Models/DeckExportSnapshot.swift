import Foundation

struct DeckExportCard: Hashable, Sendable {
    let name: String
    let imageURL: URL?
    let quantity: Int
    let borderColorName: String

    init(
        name: String,
        imageURL: URL?,
        quantity: Int,
        borderColorName: String = CardBorderColorName.defaultValue
    ) {
        self.name = name
        self.imageURL = imageURL
        self.quantity = quantity
        self.borderColorName = CardBorderColorName.normalized(borderColorName)
    }

    init(name: String, imageURL: URL?, quantity: Int) {
        self.init(
            name: name,
            imageURL: imageURL,
            quantity: quantity,
            borderColorName: CardBorderColorName.defaultValue
        )
    }
}

struct DeckExportSnapshot: Sendable {
    let deckName: String
    let scalePercent: Double
    let bleedMillimeters: Double
    let sheetCornerStyle: SheetCornerStyle
    let cards: [DeckExportCard]

    init(
        deckName: String,
        scalePercent: Double,
        bleedMillimeters: Double,
        sheetCornerStyle: SheetCornerStyle = .rounded,
        cards: [DeckExportCard]
    ) {
        self.deckName = deckName
        self.scalePercent = scalePercent
        self.bleedMillimeters = bleedMillimeters
        self.sheetCornerStyle = sheetCornerStyle
        self.cards = cards
    }

    var flattenedCards: [DeckExportCard] {
        cards.flatMap { card in
            Array(repeating: card, count: max(card.quantity, 0))
        }
    }
}
