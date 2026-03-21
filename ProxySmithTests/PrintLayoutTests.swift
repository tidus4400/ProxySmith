import CoreGraphics
import Testing
@testable import ProxySmith

struct PrintLayoutTests {
    @Test
    func fullScaleCardMatchesExpectedPhysicalSize() {
        let size = PrintLayout.cardSize(scalePercent: 100)

        #expect(size.width == 180)
        #expect(size.height == 252)
    }

    @Test
    func ninetyPercentScaleShrinksCardEvenly() {
        let size = PrintLayout.cardSize(scalePercent: 90)

        #expect(size.width == 162)
        #expect(abs(size.height - 226.8) < 0.0001)
    }

    @Test
    func pageCountUsesNineCardsPerSheet() {
        #expect(PrintLayout.pageCount(forCardCount: 0) == 0)
        #expect(PrintLayout.pageCount(forCardCount: 1) == 1)
        #expect(PrintLayout.pageCount(forCardCount: 9) == 1)
        #expect(PrintLayout.pageCount(forCardCount: 10) == 2)
    }

    @Test
    func framesStayWithinA4Page() {
        let frames = PrintLayout.cardFrames(scalePercent: 100)
        let page = CGRect(origin: .zero, size: PrintLayout.a4PageSize)

        #expect(frames.count == 9)

        for frame in frames {
            #expect(page.contains(frame))
        }
    }

    @Test
    func zeroBleedPlacementsPreserveExistingTrimGeometry() {
        let legacyFrames = PrintLayout.cardFrames(scalePercent: 100)
        let placements = PrintLayout.cardPlacements(scalePercent: 100, bleedMillimeters: 0)

        #expect(placements.map(\.trimRect) == legacyFrames)

        for placement in placements {
            #expect(placement.artworkRect == placement.trimRect)
        }
    }

    @Test
    func maximumBleedPlacementsStillFitOnA4AtFullScale() {
        let placements = PrintLayout.cardPlacements(
            scalePercent: 100,
            bleedMillimeters: PrintLayout.maximumBleedMillimeters
        )
        let page = CGRect(origin: .zero, size: PrintLayout.a4PageSize)

        #expect(placements.count == PrintLayout.cardsPerPage)

        for placement in placements {
            #expect(page.contains(placement.trimRect))
            #expect(page.contains(placement.artworkRect))
        }
    }

    @Test
    func trimAndArtworkRectsRespectBleedGutters() {
        let placements = PrintLayout.cardPlacements(scalePercent: 100, bleedMillimeters: 2)
        let tolerance: CGFloat = 0.0001

        for placement in placements {
            #expect(placement.artworkRect.contains(placement.trimRect))
        }

        for lhsIndex in placements.indices {
            for rhsIndex in placements.indices where lhsIndex < rhsIndex {
                let intersection = placements[lhsIndex].artworkRect.intersection(placements[rhsIndex].artworkRect)
                if intersection.isNull == false {
                    #expect(intersection.width <= tolerance || intersection.height <= tolerance)
                }
            }
        }
    }

    @Test
    func bleedCreatesMatchingSharedGapBetweenAdjacentTrimRects() {
        let bleedMillimeters = 2.0
        let placements = PrintLayout.cardPlacements(scalePercent: 100, bleedMillimeters: bleedMillimeters)
        let expectedGap = PrintLayout.bleedPoints(from: bleedMillimeters) * 2
        let tolerance: CGFloat = 0.0001

        let topLeft = placements[0]
        let topMiddle = placements[1]
        let middleLeft = placements[3]

        let horizontalGap = topMiddle.trimRect.minX - topLeft.trimRect.maxX
        let verticalGap = topLeft.trimRect.minY - middleLeft.trimRect.maxY

        #expect(abs(horizontalGap - expectedGap) <= tolerance)
        #expect(abs(verticalGap - expectedGap) <= tolerance)
        #expect(abs((topLeft.artworkRect.maxX - topLeft.trimRect.maxX) - (expectedGap / 2)) <= tolerance)
        #expect(abs((topMiddle.trimRect.minX - topMiddle.artworkRect.minX) - (expectedGap / 2)) <= tolerance)
    }
}
