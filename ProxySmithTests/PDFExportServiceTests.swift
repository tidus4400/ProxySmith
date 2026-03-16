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
            _ = try await service.render(
                snapshot: snapshot,
                imageRepository: CardImageRepository(),
                cacheLifetime: TimeInterval(AppPreferences.defaultCardImageCachePeriodDays * 24 * 60 * 60)
            )
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

        let data = try await service.render(
            snapshot: snapshot,
            imageRepository: CardImageRepository(),
            cacheLifetime: TimeInterval(AppPreferences.defaultCardImageCachePeriodDays * 24 * 60 * 60)
        )

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

    @Test
    func cutGuideSegmentsFollowRectangularTrimEdgeTrajectory() {
        let rect = CGRect(x: 100, y: 200, width: 180, height: 252)
        let segments = PDFExportService.cutGuideSegments(for: rect)

        let topBottomVerticalGuides = segments
            .filter { $0.start.y != $0.end.y }
            .map(\.start.x)
            .sorted()
        let leftRightHorizontalGuides = segments
            .filter { $0.start.x != $0.end.x }
            .map(\.start.y)
            .sorted()

        #expect(topBottomVerticalGuides == [rect.minX, rect.minX, rect.maxX, rect.maxX])
        #expect(leftRightHorizontalGuides == [rect.minY, rect.minY, rect.maxY, rect.maxY])
    }

    @Test
    func cutGuideSegmentsStayOnCardTrimTrajectoryForEverySupportedScale() {
        for scalePercent in 80 ... 100 {
            let frames = PrintLayout.cardFrames(scalePercent: Double(scalePercent))

            #expect(frames.count == PrintLayout.cardsPerPage)

            for frame in frames {
                assertGuidesFollowTrimTrajectory(for: frame)
            }
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

private func assertGuidesFollowTrimTrajectory(for rect: CGRect) {
    let segments = PDFExportService.cutGuideSegments(for: rect)
    let tolerance: CGFloat = 0.0001

    let verticalGuides = segments.filter { abs($0.start.x - $0.end.x) <= tolerance }
    let horizontalGuides = segments.filter { abs($0.start.y - $0.end.y) <= tolerance }

    #expect(verticalGuides.count == 4)
    #expect(horizontalGuides.count == 4)

    let verticalXs = verticalGuides.map(\.start.x).sorted()
    let horizontalYs = horizontalGuides.map(\.start.y).sorted()

    #expect(approxEqual(verticalXs[0], rect.minX, tolerance: tolerance))
    #expect(approxEqual(verticalXs[1], rect.minX, tolerance: tolerance))
    #expect(approxEqual(verticalXs[2], rect.maxX, tolerance: tolerance))
    #expect(approxEqual(verticalXs[3], rect.maxX, tolerance: tolerance))
    #expect(approxEqual(horizontalYs[0], rect.minY, tolerance: tolerance))
    #expect(approxEqual(horizontalYs[1], rect.minY, tolerance: tolerance))
    #expect(approxEqual(horizontalYs[2], rect.maxY, tolerance: tolerance))
    #expect(approxEqual(horizontalYs[3], rect.maxY, tolerance: tolerance))

    for segment in segments {
        #expect(rect.contains(segment.start) == false)
        #expect(rect.contains(segment.end) == false)
        #expect(segment.isOutside(rect))
    }
}

private func approxEqual(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat) -> Bool {
    abs(lhs - rhs) <= tolerance
}
