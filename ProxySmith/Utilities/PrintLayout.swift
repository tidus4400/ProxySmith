import CoreGraphics
import Foundation

struct PrintCardPlacement: Equatable {
    let trimRect: CGRect
    let artworkRect: CGRect
}

enum PrintLayout {
    static let a4PageSize = CGSize(width: 595.2756, height: 841.8898)
    static let cardSizeAtFullScale = CGSize(width: 180, height: 252)
    static let cardsPerPage = 9
    static let columns = 3
    static let rows = 3
    static let maximumBleedMillimeters = 2.0
    private static let pointsPerMillimeter: CGFloat = 72.0 / 25.4

    static func scale(from percentage: Double) -> Double {
        max(0.5, min(percentage / 100.0, 1.2))
    }

    static func bleed(from millimeters: Double) -> Double {
        max(0, min(millimeters, maximumBleedMillimeters))
    }

    static func bleedPoints(from millimeters: Double) -> CGFloat {
        CGFloat(bleed(from: millimeters)) * pointsPerMillimeter
    }

    static func cardSize(scalePercent: Double) -> CGSize {
        let factor = CGFloat(scale(from: scalePercent))
        return CGSize(
            width: cardSizeAtFullScale.width * factor,
            height: cardSizeAtFullScale.height * factor
        )
    }

    static func cardFrames(scalePercent: Double, pageSize: CGSize = a4PageSize) -> [CGRect] {
        cardPlacements(scalePercent: scalePercent, bleedMillimeters: 0, pageSize: pageSize)
            .map(\.trimRect)
    }

    static func cardPlacements(
        scalePercent: Double,
        bleedMillimeters: Double,
        pageSize: CGSize = a4PageSize
    ) -> [PrintCardPlacement] {
        let trimSize = cardSize(scalePercent: scalePercent)
        let bleedPoints = bleedPoints(from: bleedMillimeters)
        let artworkSize = CGSize(
            width: trimSize.width + (bleedPoints * 2),
            height: trimSize.height + (bleedPoints * 2)
        )
        let totalWidth = artworkSize.width * CGFloat(columns)
        let totalHeight = artworkSize.height * CGFloat(rows)
        let marginX = max(0, (pageSize.width - totalWidth) / 2)
        let marginY = max(0, (pageSize.height - totalHeight) / 2)

        return (0 ..< cardsPerPage).map { index in
            let row = index / columns
            let column = index % columns
            let artworkX = marginX + (CGFloat(column) * artworkSize.width)
            let artworkY = pageSize.height - marginY - artworkSize.height - (CGFloat(row) * artworkSize.height)
            let artworkRect = CGRect(
                x: artworkX,
                y: artworkY,
                width: artworkSize.width,
                height: artworkSize.height
            )
            let trimRect = artworkRect.insetBy(dx: bleedPoints, dy: bleedPoints)

            return PrintCardPlacement(trimRect: trimRect, artworkRect: artworkRect)
        }
    }

    static func pageCount(forCardCount count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(ceil(Double(count) / Double(cardsPerPage)))
    }
}
