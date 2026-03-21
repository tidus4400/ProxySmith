import CoreGraphics
import Foundation
import Testing
@testable import ProxySmith

struct PDFExportServiceTests {
    @Test
    func renderRejectsEmptyDecks() async {
        let service = PDFExportService()
        let snapshot = DeckExportSnapshot(deckName: "Empty", scalePercent: 100, bleedMillimeters: 0, cards: [])

        do {
            _ = try await service.render(
                snapshot: snapshot,
                imageRepository: CardImageRepository(),
                cacheLifetime: defaultCacheLifetime
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
            bleedMillimeters: 0,
            cards: [
                DeckExportCard(name: "Lightning Bolt", imageURL: nil, quantity: 1)
            ]
        )

        let data = try await service.render(
            snapshot: snapshot,
            imageRepository: CardImageRepository(),
            cacheLifetime: defaultCacheLifetime
        )

        #expect(data.isEmpty == false)
        #expect(data.starts(with: Data("%PDF".utf8)))
    }

    @Test
    func renderProducesPdfDataForPlaceholderCardsWithBleed() async throws {
        let service = PDFExportService()
        let snapshot = DeckExportSnapshot(
            deckName: "Preview",
            scalePercent: 100,
            bleedMillimeters: 1.5,
            cards: [
                DeckExportCard(name: "Counterspell", imageURL: nil, quantity: 1)
            ]
        )

        let data = try await service.render(
            snapshot: snapshot,
            imageRepository: CardImageRepository(),
            cacheLifetime: defaultCacheLifetime
        )

        #expect(data.isEmpty == false)
        #expect(data.starts(with: Data("%PDF".utf8)))
    }

    @Test
    func renderProducesPdfDataForStraightCornerSheetsWithBleed() async throws {
        let service = PDFExportService()
        let snapshot = DeckExportSnapshot(
            deckName: "Preview",
            scalePercent: 100,
            bleedMillimeters: 2,
            sheetCornerStyle: .straight,
            cards: [
                DeckExportCard(name: "Straight Corner Proxy", imageURL: nil, quantity: 1, borderColorName: "gold")
            ]
        )

        let data = try await service.render(
            snapshot: snapshot,
            imageRepository: CardImageRepository(),
            cacheLifetime: defaultCacheLifetime
        )

        #expect(data.isEmpty == false)
        #expect(data.starts(with: Data("%PDF".utf8)))
    }

    @Test
    func sampledBleedPaletteUsesPerSideAverageAndIgnoresTransparentPixels() throws {
        let image = try makeEdgeSampleImage()

        let palette = try #require(PDFExportService.sampledBleedPalette(from: image))

        #expect(colorsApproximatelyEqual(palette.top, PDFColor(red: 1, green: 0, blue: 0)))
        #expect(colorsApproximatelyEqual(palette.right, PDFColor(red: 1, green: 1, blue: 0)))
        #expect(colorsApproximatelyEqual(palette.bottom, PDFColor(red: 0, green: 0, blue: 1)))
        #expect(colorsApproximatelyEqual(palette.left, PDFColor(red: 0, green: 1, blue: 0)))
        #expect(colorsApproximatelyEqual(
            palette.topLeft,
            PDFColor(red: 0.5, green: 0.5, blue: 0)
        ))
        #expect(colorsApproximatelyEqual(
            palette.bottomRight,
            PDFColor(red: 0.5, green: 0.5, blue: 0.5)
        ))
    }

    @Test
    func renderInstructionsPreferSampledPaletteAndCarryCornerStyle() {
        let imageURL = URL(string: "https://example.com/card.png")!
        let sampledPalette = PDFCardEdgePalette(
            top: PDFColor(red: 0.9, green: 0.1, blue: 0.1),
            right: PDFColor(red: 0.8, green: 0.7, blue: 0.1),
            bottom: PDFColor(red: 0.1, green: 0.2, blue: 0.9),
            left: PDFColor(red: 0.2, green: 0.8, blue: 0.2)
        )

        let instructions = PDFExportService.renderInstructions(
            cards: [
                DeckExportCard(name: "Sampled Proxy", imageURL: imageURL, quantity: 1, borderColorName: "black")
            ],
            scalePercent: 100,
            bleedMillimeters: 2,
            sheetCornerStyle: .straight,
            sampledPalettesByURL: [imageURL: sampledPalette]
        )

        let instruction = instructions[0][0]

        #expect(instruction.palette == sampledPalette)
        #expect(instruction.cornerStyle == .straight)
        #expect(instruction.bleedRect.contains(instruction.trimRect))
        #expect(rectsApproximatelyEqual(instruction.bleedGrid.center, instruction.trimRect))
        #expect(instruction.trimGrid.center.width < instruction.trimRect.width)
        #expect(instruction.trimGrid.center.height < instruction.trimRect.height)
    }

    @Test
    func renderInstructionsFallBackToBorderColorWhenSampledPaletteIsUnavailable() {
        let imageURL = URL(string: "https://example.com/missing-card.png")!
        let fallbackPalette = PDFExportService.fallbackBleedPalette(for: "gold")

        let instructions = PDFExportService.renderInstructions(
            cards: [
                DeckExportCard(name: "Fallback Proxy", imageURL: imageURL, quantity: 1, borderColorName: "gold")
            ],
            scalePercent: 100,
            bleedMillimeters: 2
        )

        let instruction = instructions[0][0]

        #expect(instruction.palette == fallbackPalette)
        #expect(instruction.cornerStyle == .rounded)
    }

    @Test
    func renderInstructionsKeepCardArtOnTrimAndCarryBleedBounds() {
        let bleedMillimeters = 2.0
        let cards = [
            DeckExportCard(name: "Golden Proxy", imageURL: nil, quantity: 1, borderColorName: "gold")
        ]

        let instructions = PDFExportService.renderInstructions(
            cards: cards,
            scalePercent: 100,
            bleedMillimeters: bleedMillimeters
        )
        let placement = PrintLayout.cardPlacements(scalePercent: 100, bleedMillimeters: bleedMillimeters)[0]
        let expectedGapHalf = PrintLayout.bleedPoints(from: bleedMillimeters)
        let tolerance: CGFloat = 0.0001

        #expect(instructions.count == 1)
        #expect(instructions[0].count == 1)

        let instruction = instructions[0][0]

        #expect(instruction.card.borderColorName == "gold")
        #expect(instruction.trimRect == placement.trimRect)
        #expect(instruction.bleedRect == placement.artworkRect)
        #expect(instruction.bleedRect.contains(instruction.trimRect))
        #expect(instruction.bleedRect != instruction.trimRect)
        #expect(instruction.palette == PDFExportService.fallbackBleedPalette(for: "gold"))
        #expect(abs(instruction.bleedInset - expectedGapHalf) <= tolerance)
    }

    @Test
    func renderInstructionsSplitSharedBleedGapBetweenNeighboringCards() {
        let bleedMillimeters = 2.0
        let instructions = PDFExportService.renderInstructions(
            cards: [
                DeckExportCard(name: "Black Border", imageURL: nil, quantity: 1, borderColorName: "black"),
                DeckExportCard(name: "Gold Border", imageURL: nil, quantity: 1, borderColorName: "gold")
            ],
            scalePercent: 100,
            bleedMillimeters: bleedMillimeters
        )
        let expectedGap = PrintLayout.bleedPoints(from: bleedMillimeters) * 2
        let tolerance: CGFloat = 0.0001

        #expect(instructions.count == 1)
        #expect(instructions[0].count == 2)

        let left = instructions[0][0]
        let right = instructions[0][1]

        #expect(left.card.borderColorName == "black")
        #expect(right.card.borderColorName == "gold")
        #expect(abs(left.bleedRect.maxX - right.bleedRect.minX) <= tolerance)
        #expect(abs((right.trimRect.minX - left.trimRect.maxX) - expectedGap) <= tolerance)
        #expect(abs((left.bleedRect.maxX - left.trimRect.maxX) - (expectedGap / 2)) <= tolerance)
        #expect(abs((right.trimRect.minX - right.bleedRect.minX) - (expectedGap / 2)) <= tolerance)
        #expect(abs(left.bleedGrid.right.width - (expectedGap / 2)) <= tolerance)
        #expect(abs(right.bleedGrid.left.width - (expectedGap / 2)) <= tolerance)
    }

    @Test
    func renderSupportsMultipleBorderColorsWithBleedAcrossCornerStyles() async throws {
        let service = PDFExportService()

        for sheetCornerStyle in SheetCornerStyle.allCases {
            let snapshot = DeckExportSnapshot(
                deckName: "Preview",
                scalePercent: 100,
                bleedMillimeters: 2,
                sheetCornerStyle: sheetCornerStyle,
                cards: [
                    DeckExportCard(name: "Black Border", imageURL: nil, quantity: 1, borderColorName: "black"),
                    DeckExportCard(name: "Gold Border", imageURL: nil, quantity: 1, borderColorName: "gold")
                ]
            )

            let data = try await service.render(
                snapshot: snapshot,
                imageRepository: CardImageRepository(),
                cacheLifetime: defaultCacheLifetime
            )

            #expect(data.isEmpty == false)
            #expect(data.starts(with: Data("%PDF".utf8)))
        }
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
        let scalePercents = [80.0, 90.0, 100.0]
        let bleedValues = [0.0, 1.0, 2.0]

        for scalePercent in scalePercents {
            for bleedMillimeters in bleedValues {
                let placements = PrintLayout.cardPlacements(
                    scalePercent: scalePercent,
                    bleedMillimeters: bleedMillimeters
                )

                #expect(placements.count == PrintLayout.cardsPerPage)

                for placement in placements {
                    assertGuidesFollowTrimTrajectory(for: placement)
                }
            }
        }
    }
}

private let defaultCacheLifetime = TimeInterval(AppPreferences.defaultCardImageCachePeriodDays * 24 * 60 * 60)

private struct TestPixel {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    static func rgba(_ red: UInt8, _ green: UInt8, _ blue: UInt8, _ alpha: UInt8 = 255) -> TestPixel {
        TestPixel(red: red, green: green, blue: blue, alpha: alpha)
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

private func assertGuidesFollowTrimTrajectory(for placement: PrintCardPlacement) {
    let segments = PDFExportService.cutGuideSegments(for: placement.trimRect)
    let tolerance: CGFloat = 0.0001

    let verticalGuides = segments.filter { abs($0.start.x - $0.end.x) <= tolerance }
    let horizontalGuides = segments.filter { abs($0.start.y - $0.end.y) <= tolerance }

    #expect(verticalGuides.count == 4)
    #expect(horizontalGuides.count == 4)

    let verticalXs = verticalGuides.map(\.start.x).sorted()
    let horizontalYs = horizontalGuides.map(\.start.y).sorted()

    #expect(approxEqual(verticalXs[0], placement.trimRect.minX, tolerance: tolerance))
    #expect(approxEqual(verticalXs[1], placement.trimRect.minX, tolerance: tolerance))
    #expect(approxEqual(verticalXs[2], placement.trimRect.maxX, tolerance: tolerance))
    #expect(approxEqual(verticalXs[3], placement.trimRect.maxX, tolerance: tolerance))
    #expect(approxEqual(horizontalYs[0], placement.trimRect.minY, tolerance: tolerance))
    #expect(approxEqual(horizontalYs[1], placement.trimRect.minY, tolerance: tolerance))
    #expect(approxEqual(horizontalYs[2], placement.trimRect.maxY, tolerance: tolerance))
    #expect(approxEqual(horizontalYs[3], placement.trimRect.maxY, tolerance: tolerance))

    if placement.artworkRect != placement.trimRect {
        #expect(approxEqual(verticalXs[0], placement.artworkRect.minX, tolerance: tolerance) == false)
        #expect(approxEqual(verticalXs[2], placement.artworkRect.maxX, tolerance: tolerance) == false)
        #expect(approxEqual(horizontalYs[0], placement.artworkRect.minY, tolerance: tolerance) == false)
        #expect(approxEqual(horizontalYs[2], placement.artworkRect.maxY, tolerance: tolerance) == false)
    }

    for segment in segments {
        #expect(placement.trimRect.contains(segment.start) == false)
        #expect(placement.trimRect.contains(segment.end) == false)
        #expect(segment.isOutside(placement.trimRect))
    }
}

private func approxEqual(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat) -> Bool {
    abs(lhs - rhs) <= tolerance
}

private func rectsApproximatelyEqual(
    _ lhs: CGRect,
    _ rhs: CGRect,
    tolerance: CGFloat = 0.0001
) -> Bool {
    approxEqual(lhs.minX, rhs.minX, tolerance: tolerance) &&
    approxEqual(lhs.minY, rhs.minY, tolerance: tolerance) &&
    approxEqual(lhs.width, rhs.width, tolerance: tolerance) &&
    approxEqual(lhs.height, rhs.height, tolerance: tolerance)
}

private func colorsApproximatelyEqual(
    _ lhs: PDFColor,
    _ rhs: PDFColor,
    tolerance: Double = 0.0001
) -> Bool {
    abs(lhs.red - rhs.red) <= tolerance &&
    abs(lhs.green - rhs.green) <= tolerance &&
    abs(lhs.blue - rhs.blue) <= tolerance &&
    abs(lhs.alpha - rhs.alpha) <= tolerance
}

private func makeEdgeSampleImage() throws -> CGImage {
    let rows: [[TestPixel]] = [
        [.rgba(0, 0, 0, 0), .rgba(255, 0, 0), .rgba(255, 0, 0), .rgba(0, 0, 0, 0)],
        [.rgba(0, 255, 0), .rgba(0, 0, 0, 0), .rgba(0, 0, 0, 0), .rgba(255, 255, 0)],
        [.rgba(0, 255, 0), .rgba(0, 0, 0, 0), .rgba(0, 0, 0, 0), .rgba(255, 255, 0)],
        [.rgba(0, 0, 0, 0), .rgba(0, 0, 255), .rgba(0, 0, 255), .rgba(0, 0, 0, 0)]
    ]

    return try makeImage(from: rows)
}

private func makeImage(from rows: [[TestPixel]]) throws -> CGImage {
    let height = rows.count
    let width = try #require(rows.first?.count)
    #expect(rows.allSatisfy { $0.count == width })

    var bytes: [UInt8] = []
    bytes.reserveCapacity(width * height * 4)

    for row in rows {
        for pixel in row {
            bytes.append(pixel.red)
            bytes.append(pixel.green)
            bytes.append(pixel.blue)
            bytes.append(pixel.alpha)
        }
    }

    let data = Data(bytes)
    let provider = try #require(CGDataProvider(data: data as CFData))
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(.init(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))

    return try #require(CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo,
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ))
}
