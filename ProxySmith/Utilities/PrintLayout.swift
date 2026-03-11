import CoreGraphics
import Foundation

enum PrintLayout {
    static let a4PageSize = CGSize(width: 595.2756, height: 841.8898)
    static let cardSizeAtFullScale = CGSize(width: 180, height: 252)
    static let cardsPerPage = 9
    static let columns = 3
    static let rows = 3

    static func scale(from percentage: Double) -> Double {
        max(0.5, min(percentage / 100.0, 1.2))
    }

    static func cardSize(scalePercent: Double) -> CGSize {
        let factor = scale(from: scalePercent)
        return CGSize(
            width: cardSizeAtFullScale.width * factor,
            height: cardSizeAtFullScale.height * factor
        )
    }

    static func cardFrames(scalePercent: Double, pageSize: CGSize = a4PageSize) -> [CGRect] {
        let cardSize = cardSize(scalePercent: scalePercent)
        let totalWidth = cardSize.width * Double(columns)
        let totalHeight = cardSize.height * Double(rows)
        let marginX = max(0, (pageSize.width - totalWidth) / 2)
        let marginY = max(0, (pageSize.height - totalHeight) / 2)

        return (0 ..< cardsPerPage).map { index in
            let row = index / columns
            let column = index % columns
            let x = marginX + (Double(column) * cardSize.width)
            let y = pageSize.height - marginY - cardSize.height - (Double(row) * cardSize.height)

            return CGRect(x: x, y: y, width: cardSize.width, height: cardSize.height)
        }
    }

    static func pageCount(forCardCount count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int(ceil(Double(count) / Double(cardsPerPage)))
    }
}

