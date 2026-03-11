import Foundation

struct DeckExportCard: Hashable, Sendable {
    let name: String
    let imageURL: URL?
    let quantity: Int
}

struct DeckExportSnapshot: Sendable {
    let deckName: String
    let scalePercent: Double
    let cards: [DeckExportCard]

    var flattenedCards: [DeckExportCard] {
        cards.flatMap { card in
            Array(repeating: card, count: max(card.quantity, 0))
        }
    }
}

