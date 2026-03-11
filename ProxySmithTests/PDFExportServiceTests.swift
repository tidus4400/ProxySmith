import Foundation
import CoreGraphics
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

    @Test
    func cutGuideSegmentsStayOutsideCardArtworkBounds() {
        let rect = CGRect(x: 100, y: 200, width: 180, height: 252)
        let segments = PDFExportService.cutGuideSegments(for: rect)

        #expect(segments.count == 8)

        for segment in segments {
            #expect(rect.contains(segment.start) == false)
            #expect(rect.contains(segment.end) == false)
            #expect(segment.isOutside(rect))
        }
    }
}

private extension CutGuideSegment {
    func isOutside(_ rect: CGRect) -> Bool {
        let isLeftOfCard = start.x < rect.minX && end.x < rect.minX
        let isRightOfCard = start.x > rect.maxX && end.x > rect.maxX
        let isBelowCard = start.y < rect.minY && end.y < rect.minY
        let isAboveCard = start.y > rect.maxY && end.y > rect.maxY

        return isLeftOfCard || isRightOfCard || isBelowCard || isAboveCard
    }
}
