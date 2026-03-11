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
}
