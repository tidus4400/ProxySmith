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

struct PDFExportService {
    func export(snapshot: DeckExportSnapshot, to url: URL, imageRepository: CardImageRepository) async throws {
        let data = try await render(snapshot: snapshot, imageRepository: imageRepository)
        try data.write(to: url, options: .atomic)
    }

    func render(snapshot: DeckExportSnapshot, imageRepository: CardImageRepository) async throws -> Data {
        let cards = snapshot.flattenedCards
        guard !cards.isEmpty else {
            throw PDFExportError.noCards
        }

        let uniqueImageURLs = Array(Set(cards.compactMap(\.imageURL)))
        let imageData = try await imageRepository.prefetchData(for: uniqueImageURLs)

        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: PrintLayout.a4PageSize)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.couldNotCreateFile
        }

        renderPages(
            cards: cards,
            imageData: imageData,
            scalePercent: snapshot.scalePercent,
            mediaBox: mediaBox,
            context: context
        )

        return data as Data
    }

    private func renderPages(
        cards: [DeckExportCard],
        imageData: [URL: Data],
        scalePercent: Double,
        mediaBox: CGRect,
        context: CGContext
    ) {
        let frames = PrintLayout.cardFrames(scalePercent: scalePercent)
        let pages = stride(from: 0, to: cards.count, by: PrintLayout.cardsPerPage)

        for pageStart in pages {
            context.beginPDFPage(nil)
            drawPageBackground(in: context, pageRect: mediaBox)

            let pageCards = Array(cards[pageStart ..< min(pageStart + PrintLayout.cardsPerPage, cards.count)])

            for (index, card) in pageCards.enumerated() {
                let frame = frames[index]
                if let imageURL = card.imageURL,
                   let data = imageData[imageURL],
                   let cgImage = makeImage(from: data) {
                    context.interpolationQuality = .high
                    context.draw(cgImage, in: frame)
                } else {
                    drawPlaceholder(for: card.name, in: frame, context: context)
                }

                drawGuides(for: frame, in: context)
            }

            context.endPDFPage()
        }

        context.closePDF()
    }

    private func makeImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func drawPageBackground(in context: CGContext, pageRect: CGRect) {
        context.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
        context.fill(pageRect)
    }

    private func drawPlaceholder(for name: String, in rect: CGRect, context: CGContext) {
        context.setFillColor(CGColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1))
        context.fill(rect)
        context.setStrokeColor(CGColor(red: 0.82, green: 0.79, blue: 0.74, alpha: 1))
        context.stroke(rect, width: 1)
        context.saveGState()
        context.translateBy(x: rect.midX, y: rect.midY)
        context.rotate(by: -.pi / 2)
        let text = name as CFString
        let attributes = [
            NSAttributedString.Key.font: CTFontCreateWithName("SFProRounded-Semibold" as CFString, 15, nil),
            NSAttributedString.Key.foregroundColor: CGColor(gray: 0.18, alpha: 1)
        ] as CFDictionary
        let attributed = CFAttributedStringCreate(nil, text, attributes)!
        let line = CTLineCreateWithAttributedString(attributed)
        context.textPosition = CGPoint(x: -rect.height * 0.38, y: -6)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private func drawGuides(for rect: CGRect, in context: CGContext) {
        context.setStrokeColor(CGColor(gray: 0.28, alpha: 0.65))
        context.setLineWidth(0.4)
        context.stroke(rect)

        let markLength: CGFloat = 9
        let horizontalInset = max(6, min(12, rect.width * 0.06))
        let verticalInset = max(6, min(12, rect.height * 0.04))

        func stroke(_ start: CGPoint, _ end: CGPoint) {
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }

        stroke(CGPoint(x: rect.minX, y: rect.maxY - verticalInset), CGPoint(x: rect.minX - markLength, y: rect.maxY - verticalInset))
        stroke(CGPoint(x: rect.minX + horizontalInset, y: rect.maxY), CGPoint(x: rect.minX + horizontalInset, y: rect.maxY + markLength))
        stroke(CGPoint(x: rect.maxX, y: rect.maxY - verticalInset), CGPoint(x: rect.maxX + markLength, y: rect.maxY - verticalInset))
        stroke(CGPoint(x: rect.maxX - horizontalInset, y: rect.maxY), CGPoint(x: rect.maxX - horizontalInset, y: rect.maxY + markLength))
        stroke(CGPoint(x: rect.minX, y: rect.minY + verticalInset), CGPoint(x: rect.minX - markLength, y: rect.minY + verticalInset))
        stroke(CGPoint(x: rect.minX + horizontalInset, y: rect.minY), CGPoint(x: rect.minX + horizontalInset, y: rect.minY - markLength))
        stroke(CGPoint(x: rect.maxX, y: rect.minY + verticalInset), CGPoint(x: rect.maxX + markLength, y: rect.minY + verticalInset))
        stroke(CGPoint(x: rect.maxX - horizontalInset, y: rect.minY), CGPoint(x: rect.maxX - horizontalInset, y: rect.minY - markLength))
    }
}
