import Foundation
import SwiftData

enum SheetCornerStyle: String, CaseIterable, Codable, Sendable {
    case rounded
    case straight

    var displayName: String {
        switch self {
        case .rounded:
            return "Rounded"
        case .straight:
            return "Straight"
        }
    }

    static let defaultValue: SheetCornerStyle = .rounded
}

@Model
final class Deck {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var scalePercent: Double
    var bleedMillimeters: Double = 0
    var sheetCornerStyleRawValue: String = SheetCornerStyle.defaultValue.rawValue

    @Relationship(deleteRule: .cascade, inverse: \DeckCard.deck)
    var cards: [DeckCard]

    init(
        id: UUID = UUID(),
        name: String = "Untitled Deck",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        scalePercent: Double = 100,
        bleedMillimeters: Double = 0,
        sheetCornerStyle: SheetCornerStyle = .rounded
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.scalePercent = scalePercent
        self.bleedMillimeters = bleedMillimeters
        self.sheetCornerStyleRawValue = sheetCornerStyle.rawValue
        self.cards = []
    }

    var sheetCornerStyle: SheetCornerStyle {
        get { SheetCornerStyle(rawValue: sheetCornerStyleRawValue) ?? .rounded }
        set { sheetCornerStyleRawValue = newValue.rawValue }
    }

    var sortedCards: [DeckCard] {
        cards.sorted { lhs, rhs in
            if lhs.name == rhs.name {
                return lhs.collectorNumber.localizedStandardCompare(rhs.collectorNumber) == .orderedAscending
            }

            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    var totalCardCount: Int {
        cards.reduce(0) { $0 + $1.quantity }
    }

    var exportSnapshot: DeckExportSnapshot {
        DeckExportSnapshot(
            deckName: name,
            scalePercent: scalePercent,
            bleedMillimeters: bleedMillimeters,
            sheetCornerStyle: sheetCornerStyle,
            cards: sortedCards.map { $0.exportCard }
        )
    }

    func touch() {
        updatedAt = .now
    }

    func addCard(from scryfallCard: ScryfallCard) {
        if let existing = cards.first(where: { $0.scryfallID == scryfallCard.id }) {
            existing.quantity += 1
            touch()
            return
        }

        let card = DeckCard(scryfallCard: scryfallCard, deck: self)
        cards.append(card)
        touch()
    }
}
