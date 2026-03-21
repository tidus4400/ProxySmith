import CoreGraphics
import CoreText
import Foundation
import ImageIO

enum PDFExportError: Error, Equatable, LocalizedError {
    case noCards
    case couldNotCreateFile

    var errorDescription: String? {
        switch self {
        case .noCards:
            return "Add at least one card before exporting print sheets."
        case .couldNotCreateFile:
            return "ProxySmith could not create the PDF file."
        }
    }
}

struct CutGuideSegment: Equatable {
    let start: CGPoint
    let end: CGPoint
}

struct PDFColor: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
        self.alpha = Self.clamp(alpha)
    }

    init(cgColor: CGColor) {
        let converted = cgColor.converted(
            to: CGColorSpaceCreateDeviceRGB(),
            intent: .defaultIntent,
            options: nil
        ) ?? cgColor
        let components = converted.components ?? [0, 0, 0, 1]

        switch components.count {
        case 4:
            self.init(
                red: Double(components[0]),
                green: Double(components[1]),
                blue: Double(components[2]),
                alpha: Double(components[3])
            )
        case 2:
            self.init(
                red: Double(components[0]),
                green: Double(components[0]),
                blue: Double(components[0]),
                alpha: Double(components[1])
            )
        default:
            self.init(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }

    var cgColor: CGColor {
        CGColor(
            red: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(alpha)
        )
    }

    func blended(with other: PDFColor) -> PDFColor {
        .init(
            red: (red + other.red) / 2,
            green: (green + other.green) / 2,
            blue: (blue + other.blue) / 2,
            alpha: (alpha + other.alpha) / 2
        )
    }

    static func average(_ colors: [PDFColor]) -> PDFColor {
        guard colors.isEmpty == false else {
            return .init(red: 0, green: 0, blue: 0, alpha: 1)
        }

        let count = Double(colors.count)
        return .init(
            red: colors.reduce(0) { $0 + $1.red } / count,
            green: colors.reduce(0) { $0 + $1.green } / count,
            blue: colors.reduce(0) { $0 + $1.blue } / count,
            alpha: colors.reduce(0) { $0 + $1.alpha } / count
        )
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

struct PDFCardEdgePalette: Equatable, Sendable {
    let top: PDFColor
    let right: PDFColor
    let bottom: PDFColor
    let left: PDFColor
    let topLeft: PDFColor
    let topRight: PDFColor
    let bottomLeft: PDFColor
    let bottomRight: PDFColor
    let center: PDFColor

    init(top: PDFColor, right: PDFColor, bottom: PDFColor, left: PDFColor) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
        self.topLeft = top.blended(with: left)
        self.topRight = top.blended(with: right)
        self.bottomLeft = bottom.blended(with: left)
        self.bottomRight = bottom.blended(with: right)
        self.center = PDFColor.average([top, right, bottom, left])
    }

    static func uniform(_ color: PDFColor) -> PDFCardEdgePalette {
        .init(top: color, right: color, bottom: color, left: color)
    }
}

struct PDFRegionGrid: Equatable {
    let topLeft: CGRect
    let top: CGRect
    let topRight: CGRect
    let left: CGRect
    let center: CGRect
    let right: CGRect
    let bottomLeft: CGRect
    let bottom: CGRect
    let bottomRight: CGRect
}

struct PDFRenderInstruction: Equatable {
    let card: DeckExportCard
    let trimRect: CGRect
    let bleedRect: CGRect
    let bleedGrid: PDFRegionGrid
    let trimGrid: PDFRegionGrid
    let palette: PDFCardEdgePalette
    let cornerStyle: SheetCornerStyle
    let cornerRadius: CGFloat
    let bleedInset: CGFloat
}

private struct PDFCardImageAsset {
    let image: CGImage
    let sampledPalette: PDFCardEdgePalette?
}

private struct RGBAImageBuffer {
    private static let visibleAlphaThreshold = 0.01

    let width: Int
    let height: Int
    let bytesPerRow: Int
    let pixels: [UInt8]

    init?(image: CGImage) {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4

        var rawPixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        let context = rawPixels.withUnsafeMutableBytes { bytes -> CGContext? in
            guard let baseAddress = bytes.baseAddress else { return nil }
            return CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            )
        }

        guard let context else { return nil }

        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
        pixels = rawPixels
    }

    func sampledColor(xRange: Range<Int>, yRange: Range<Int>) -> PDFColor? {
        let clampedXRange = max(0, xRange.lowerBound) ..< min(width, xRange.upperBound)
        let clampedYRange = max(0, yRange.lowerBound) ..< min(height, yRange.upperBound)

        guard clampedXRange.isEmpty == false, clampedYRange.isEmpty == false else {
            return nil
        }

        var weightedRed = 0.0
        var weightedGreen = 0.0
        var weightedBlue = 0.0
        var totalWeight = 0.0

        for y in clampedYRange {
            for x in clampedXRange {
                let offset = (y * bytesPerRow) + (x * 4)
                let alpha = Double(pixels[offset + 3]) / 255.0
                guard alpha > Self.visibleAlphaThreshold else { continue }

                let red = min((Double(pixels[offset]) / 255.0) / alpha, 1.0)
                let green = min((Double(pixels[offset + 1]) / 255.0) / alpha, 1.0)
                let blue = min((Double(pixels[offset + 2]) / 255.0) / alpha, 1.0)

                weightedRed += red * alpha
                weightedGreen += green * alpha
                weightedBlue += blue * alpha
                totalWeight += alpha
            }
        }

        guard totalWeight > 0 else { return nil }

        return PDFColor(
            red: weightedRed / totalWeight,
            green: weightedGreen / totalWeight,
            blue: weightedBlue / totalWeight,
            alpha: 1
        )
    }
}

struct PDFExportService {
    func export(
        snapshot: DeckExportSnapshot,
        to url: URL,
        imageRepository: CardImageRepository,
        cacheLifetime: TimeInterval
    ) async throws {
        let data = try await render(
            snapshot: snapshot,
            imageRepository: imageRepository,
            cacheLifetime: cacheLifetime
        )
        try data.write(to: url, options: .atomic)
    }

    func render(
        snapshot: DeckExportSnapshot,
        imageRepository: CardImageRepository,
        cacheLifetime: TimeInterval
    ) async throws -> Data {
        let cards = snapshot.flattenedCards
        guard cards.isEmpty == false else {
            throw PDFExportError.noCards
        }

        let uniqueImageURLs = Array(Set(cards.compactMap(\.imageURL)))
        let imageData = try await imageRepository.prefetchData(
            for: uniqueImageURLs,
            maxAge: cacheLifetime
        )
        let imageAssets = makeImageAssets(from: imageData)

        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: PrintLayout.a4PageSize)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.couldNotCreateFile
        }

        renderPages(
            cards: cards,
            imageAssets: imageAssets,
            scalePercent: snapshot.scalePercent,
            bleedMillimeters: snapshot.bleedMillimeters,
            sheetCornerStyle: snapshot.sheetCornerStyle,
            mediaBox: mediaBox,
            context: context
        )

        return data as Data
    }

    private func renderPages(
        cards: [DeckExportCard],
        imageAssets: [URL: PDFCardImageAsset],
        scalePercent: Double,
        bleedMillimeters: Double,
        sheetCornerStyle: SheetCornerStyle,
        mediaBox: CGRect,
        context: CGContext
    ) {
        let sampledPalettesByURL = imageAssets.compactMapValues(\.sampledPalette)
        let instructionsByPage = Self.renderInstructions(
            cards: cards,
            scalePercent: scalePercent,
            bleedMillimeters: bleedMillimeters,
            sheetCornerStyle: sheetCornerStyle,
            sampledPalettesByURL: sampledPalettesByURL
        )

        for instructions in instructionsByPage {
            context.beginPDFPage(nil)
            drawPageBackground(in: context, pageRect: mediaBox)

            for instruction in instructions {
                drawCardBackground(instruction, context: context)

                if let imageURL = instruction.card.imageURL,
                   let asset = imageAssets[imageURL] {
                    drawImage(asset.image, for: instruction, context: context)
                } else {
                    drawPlaceholder(for: instruction.card.name, instruction: instruction, context: context)
                }

                drawGuides(for: instruction.trimRect, in: context)
            }

            context.endPDFPage()
        }

        context.closePDF()
    }

    private func makeImageAssets(from imageData: [URL: Data]) -> [URL: PDFCardImageAsset] {
        var assets: [URL: PDFCardImageAsset] = [:]

        for (url, data) in imageData {
            guard let image = makeImage(from: data) else { continue }
            assets[url] = PDFCardImageAsset(
                image: image,
                sampledPalette: Self.sampledBleedPalette(from: image)
            )
        }

        return assets
    }

    private func makeImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func drawPageBackground(in context: CGContext, pageRect: CGRect) {
        context.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
        context.fill(pageRect)
    }

    private func drawCardBackground(_ instruction: PDFRenderInstruction, context: CGContext) {
        context.saveGState()

        if instruction.cornerStyle == .rounded {
            context.addPath(Self.bleedPath(for: instruction))
            context.clip()
        }

        fill(instruction.bleedGrid, using: instruction.palette, context: context)

        if instruction.cornerStyle == .straight {
            fill(instruction.trimGrid, using: instruction.palette, context: context)
        }

        context.restoreGState()
    }

    private func fill(_ grid: PDFRegionGrid, using palette: PDFCardEdgePalette, context: CGContext) {
        fill(grid.center, color: palette.center, context: context)
        fill(grid.top, color: palette.top, context: context)
        fill(grid.right, color: palette.right, context: context)
        fill(grid.bottom, color: palette.bottom, context: context)
        fill(grid.left, color: palette.left, context: context)
        fill(grid.topLeft, color: palette.topLeft, context: context)
        fill(grid.topRight, color: palette.topRight, context: context)
        fill(grid.bottomLeft, color: palette.bottomLeft, context: context)
        fill(grid.bottomRight, color: palette.bottomRight, context: context)
    }

    private func fill(_ rect: CGRect, color: PDFColor, context: CGContext) {
        guard rect.isNull == false, rect.isEmpty == false else { return }
        context.setFillColor(color.cgColor)
        context.fill(rect)
    }

    private func drawImage(_ image: CGImage, for instruction: PDFRenderInstruction, context: CGContext) {
        context.saveGState()
        context.addPath(Self.trimPath(for: instruction))
        context.clip()
        context.interpolationQuality = .high
        context.draw(image, in: Self.aspectFillRect(for: image, in: instruction.trimRect))
        context.restoreGState()
    }

    private func drawPlaceholder(
        for name: String,
        instruction: PDFRenderInstruction,
        context: CGContext
    ) {
        let trimPath = Self.trimPath(for: instruction)

        context.saveGState()
        context.addPath(trimPath)
        context.clip()
        context.setFillColor(CGColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1))
        context.fill(instruction.trimRect)
        context.restoreGState()

        context.addPath(trimPath)
        context.setStrokeColor(CGColor(red: 0.82, green: 0.79, blue: 0.74, alpha: 1))
        context.setLineWidth(1)
        context.strokePath()

        context.saveGState()
        context.translateBy(x: instruction.trimRect.midX, y: instruction.trimRect.midY)
        context.rotate(by: -.pi / 2)
        let text = name as CFString
        let attributes = [
            NSAttributedString.Key.font: CTFontCreateWithName("SFProRounded-Semibold" as CFString, 15, nil),
            NSAttributedString.Key.foregroundColor: CGColor(gray: 0.18, alpha: 1)
        ] as CFDictionary
        let attributed = CFAttributedStringCreate(nil, text, attributes)!
        let line = CTLineCreateWithAttributedString(attributed)
        context.textPosition = CGPoint(x: -instruction.trimRect.height * 0.38, y: -6)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private func drawGuides(for rect: CGRect, in context: CGContext) {
        context.setStrokeColor(CGColor(gray: 0.28, alpha: 0.65))
        context.setLineWidth(0.4)

        for segment in Self.cutGuideSegments(for: rect) {
            context.move(to: segment.start)
            context.addLine(to: segment.end)
            context.strokePath()
        }
    }

    static func cutGuideSegments(for rect: CGRect) -> [CutGuideSegment] {
        let markLength: CGFloat = 9
        let markGap: CGFloat = 2

        return [
            CutGuideSegment(
                start: CGPoint(x: rect.minX - markGap, y: rect.maxY),
                end: CGPoint(x: rect.minX - markGap - markLength, y: rect.maxY)
            ),
            CutGuideSegment(
                start: CGPoint(x: rect.minX, y: rect.maxY + markGap),
                end: CGPoint(x: rect.minX, y: rect.maxY + markGap + markLength)
            ),
            CutGuideSegment(
                start: CGPoint(x: rect.maxX + markGap, y: rect.maxY),
                end: CGPoint(x: rect.maxX + markGap + markLength, y: rect.maxY)
            ),
            CutGuideSegment(
                start: CGPoint(x: rect.maxX, y: rect.maxY + markGap),
                end: CGPoint(x: rect.maxX, y: rect.maxY + markGap + markLength)
            ),
            CutGuideSegment(
                start: CGPoint(x: rect.minX - markGap, y: rect.minY),
                end: CGPoint(x: rect.minX - markGap - markLength, y: rect.minY)
            ),
            CutGuideSegment(
                start: CGPoint(x: rect.minX, y: rect.minY - markGap),
                end: CGPoint(x: rect.minX, y: rect.minY - markGap - markLength)
            ),
            CutGuideSegment(
                start: CGPoint(x: rect.maxX + markGap, y: rect.minY),
                end: CGPoint(x: rect.maxX + markGap + markLength, y: rect.minY)
            ),
            CutGuideSegment(
                start: CGPoint(x: rect.maxX, y: rect.minY - markGap),
                end: CGPoint(x: rect.maxX, y: rect.minY - markGap - markLength)
            )
        ]
    }

    static func bleedFillColor(for borderColorName: String) -> CGColor {
        fallbackBleedColor(for: borderColorName).cgColor
    }

    static func fallbackBleedPalette(for borderColorName: String) -> PDFCardEdgePalette {
        .uniform(fallbackBleedColor(for: borderColorName))
    }

    static func sampledBleedPalette(from image: CGImage) -> PDFCardEdgePalette? {
        guard let rasterized = RGBAImageBuffer(image: image) else { return nil }

        let depth = max(
            1,
            min(
                8,
                Int(round(Double(min(rasterized.width, rasterized.height)) * 0.006))
            )
        )

        guard let top = rasterized.sampledColor(
            xRange: 0 ..< rasterized.width,
            yRange: max(0, rasterized.height - depth) ..< rasterized.height
        ),
        let right = rasterized.sampledColor(
            xRange: max(0, rasterized.width - depth) ..< rasterized.width,
            yRange: 0 ..< rasterized.height
        ),
        let bottom = rasterized.sampledColor(
            xRange: 0 ..< rasterized.width,
            yRange: 0 ..< depth
        ),
        let left = rasterized.sampledColor(
            xRange: 0 ..< depth,
            yRange: 0 ..< rasterized.height
        ) else {
            return nil
        }

        return PDFCardEdgePalette(top: top, right: right, bottom: bottom, left: left)
    }

    static func renderInstructions(
        cards: [DeckExportCard],
        scalePercent: Double,
        bleedMillimeters: Double,
        sheetCornerStyle: SheetCornerStyle = .rounded,
        sampledPalettesByURL: [URL: PDFCardEdgePalette] = [:]
    ) -> [[PDFRenderInstruction]] {
        let placements = PrintLayout.cardPlacements(
            scalePercent: scalePercent,
            bleedMillimeters: bleedMillimeters
        )
        let pageStarts = stride(from: 0, to: cards.count, by: PrintLayout.cardsPerPage)

        return pageStarts.map { pageStart in
            let pageCards = Array(cards[pageStart ..< min(pageStart + PrintLayout.cardsPerPage, cards.count)])

            return pageCards.enumerated().map { index, card in
                let placement = placements[index]
                let bleedInset = max(0, placement.trimRect.minX - placement.artworkRect.minX)
                let cornerRadius = cardCornerRadius(for: placement.trimRect)
                let trimInset = min(cornerRadius, min(placement.trimRect.width, placement.trimRect.height) / 2)
                let trimInnerRect = placement.trimRect.insetBy(dx: trimInset, dy: trimInset)
                let palette = if let imageURL = card.imageURL,
                                 let sampledPalette = sampledPalettesByURL[imageURL] {
                    sampledPalette
                } else {
                    fallbackBleedPalette(for: card.borderColorName)
                }

                return PDFRenderInstruction(
                    card: card,
                    trimRect: placement.trimRect,
                    bleedRect: placement.artworkRect,
                    bleedGrid: regionGrid(outerRect: placement.artworkRect, innerRect: placement.trimRect),
                    trimGrid: regionGrid(outerRect: placement.trimRect, innerRect: trimInnerRect),
                    palette: palette,
                    cornerStyle: sheetCornerStyle,
                    cornerRadius: trimInset,
                    bleedInset: bleedInset
                )
            }
        }
    }

    private static func fallbackBleedColor(for borderColorName: String) -> PDFColor {
        switch CardBorderColorName.normalized(borderColorName) {
        case "white":
            return .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case "silver":
            return .init(red: 0.79, green: 0.80, blue: 0.84, alpha: 1.0)
        case "gold":
            return .init(red: 0.85, green: 0.69, blue: 0.29, alpha: 1.0)
        case "borderless":
            return .init(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        default:
            return .init(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0)
        }
    }

    private static func regionGrid(outerRect: CGRect, innerRect: CGRect) -> PDFRegionGrid {
        let normalizedOuter = outerRect.standardized
        let normalizedInner = innerRect.standardized.intersection(normalizedOuter)

        return PDFRegionGrid(
            topLeft: rect(
                x: normalizedOuter.minX,
                y: normalizedInner.maxY,
                width: normalizedInner.minX - normalizedOuter.minX,
                height: normalizedOuter.maxY - normalizedInner.maxY
            ),
            top: rect(
                x: normalizedInner.minX,
                y: normalizedInner.maxY,
                width: normalizedInner.width,
                height: normalizedOuter.maxY - normalizedInner.maxY
            ),
            topRight: rect(
                x: normalizedInner.maxX,
                y: normalizedInner.maxY,
                width: normalizedOuter.maxX - normalizedInner.maxX,
                height: normalizedOuter.maxY - normalizedInner.maxY
            ),
            left: rect(
                x: normalizedOuter.minX,
                y: normalizedInner.minY,
                width: normalizedInner.minX - normalizedOuter.minX,
                height: normalizedInner.height
            ),
            center: normalizedInner,
            right: rect(
                x: normalizedInner.maxX,
                y: normalizedInner.minY,
                width: normalizedOuter.maxX - normalizedInner.maxX,
                height: normalizedInner.height
            ),
            bottomLeft: rect(
                x: normalizedOuter.minX,
                y: normalizedOuter.minY,
                width: normalizedInner.minX - normalizedOuter.minX,
                height: normalizedInner.minY - normalizedOuter.minY
            ),
            bottom: rect(
                x: normalizedInner.minX,
                y: normalizedOuter.minY,
                width: normalizedInner.width,
                height: normalizedInner.minY - normalizedOuter.minY
            ),
            bottomRight: rect(
                x: normalizedInner.maxX,
                y: normalizedOuter.minY,
                width: normalizedOuter.maxX - normalizedInner.maxX,
                height: normalizedInner.minY - normalizedOuter.minY
            )
        )
    }

    private static func trimPath(for instruction: PDFRenderInstruction) -> CGPath {
        let cornerRadius = instruction.cornerStyle == .rounded ? instruction.cornerRadius : 0
        return roundedPath(for: instruction.trimRect, cornerRadius: cornerRadius)
    }

    private static func bleedPath(for instruction: PDFRenderInstruction) -> CGPath {
        let cornerRadius = instruction.cornerStyle == .rounded
            ? instruction.cornerRadius + instruction.bleedInset
            : 0
        return roundedPath(for: instruction.bleedRect, cornerRadius: cornerRadius)
    }

    private static func roundedPath(for rect: CGRect, cornerRadius: CGFloat) -> CGPath {
        let clampedRadius = min(cornerRadius, min(rect.width, rect.height) / 2)
        return CGPath(
            roundedRect: rect,
            cornerWidth: clampedRadius,
            cornerHeight: clampedRadius,
            transform: nil
        )
    }

    private static func cardCornerRadius(for trimRect: CGRect) -> CGFloat {
        let ratio: CGFloat = 21.0 / 362.0
        let radius = trimRect.width * ratio
        return min(max(radius, 1), min(trimRect.width, trimRect.height) / 2)
    }

    private static func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(
            x: x,
            y: y,
            width: max(0, width),
            height: max(0, height)
        )
    }

    private static func aspectFillRect(for image: CGImage, in rect: CGRect) -> CGRect {
        let imageSize = CGSize(width: CGFloat(image.width), height: CGFloat(image.height))
        let widthScale = rect.width / imageSize.width
        let heightScale = rect.height / imageSize.height
        let scale = max(widthScale, heightScale)
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        return CGRect(
            x: rect.midX - (scaledSize.width / 2),
            y: rect.midY - (scaledSize.height / 2),
            width: scaledSize.width,
            height: scaledSize.height
        )
    }
}
