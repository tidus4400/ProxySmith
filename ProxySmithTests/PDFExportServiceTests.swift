import Foundation
import Testing
@testable import ProxySmith

struct PDFExportServiceTests {
    @Test
    func renderRejectsEmptyDecks() async {
        let service = PDFExportService()
        let snapshot = DeckExportSnapshot(deckName: "Empty", scalePercent: 100, cards: [])

        do {
            _ = try await service.render(snapshot: snapshot, imageRepository: CardImageRepository())
            Issue.record("Expected empty deck rendering to fail.")
        } catch let error as PDFExportError {
            #expect(error == .noCards)
        } catch {
            Issue.record("Unexpected error: \(error.localizedDescription)")
        }
    }

    @Test
    func renderProducesPdfDataForPlaceholderCards() async throws {
        let service = PDFExportService()
        let snapshot = DeckExportSnapshot(
            deckName: "Preview",
            scalePercent: 100,
            cards: [
                DeckExportCard(name: "Lightning Bolt", imageURL: nil, quantity: 1)
            ]
        )

        let data = try await service.render(snapshot: snapshot, imageRepository: CardImageRepository())

        #expect(data.isEmpty == false)
        #expect(data.starts(with: Data("%PDF".utf8)))
    }
}
