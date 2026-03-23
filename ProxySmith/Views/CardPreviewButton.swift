import AppKit
import SwiftUI

enum CardPreviewMetrics {
    static let thumbnailCornerRadius: CGFloat = 6
    static let previewCornerRadius: CGFloat = 21
    static let previewArtworkWidth: CGFloat = 362
    static let previewArtworkHeight: CGFloat = 504
    static let previewPanelWidth: CGFloat = 410
}

struct CardPreviewButton: View {
    let previewImageURL: URL?
    let enlargedImageURL: URL?
    let title: String
    let typeLine: String
    let setLine: String
    let thumbnailWidth: CGFloat
    let thumbnailHeight: CGFloat
    let accessibilityLabel: String
    let buttonAccessibilityIdentifier: String
    let panelAccessibilityIdentifier: String
    let titleAccessibilityIdentifier: String
    var arrowEdge: Edge = .leading

    @State private var isShowingPreview = false

    var body: some View {
        Button {
            isShowingPreview.toggle()
        } label: {
            CardArtworkContent(
                url: previewImageURL ?? enlargedImageURL,
                width: thumbnailWidth,
                height: thumbnailHeight,
                cornerRadius: CardPreviewMetrics.thumbnailCornerRadius
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(buttonAccessibilityIdentifier)
        .popover(isPresented: $isShowingPreview, arrowEdge: arrowEdge) {
            CardPreviewPopoverContent(
                previewImageURL: previewImageURL,
                enlargedImageURL: enlargedImageURL,
                title: title,
                typeLine: typeLine,
                setLine: setLine,
                panelAccessibilityIdentifier: panelAccessibilityIdentifier,
                titleAccessibilityIdentifier: titleAccessibilityIdentifier
            )
        }
    }
}

private struct CardPreviewPopoverContent: View {
    @Environment(\.colorScheme) private var colorScheme

    let previewImageURL: URL?
    let enlargedImageURL: URL?
    let title: String
    let typeLine: String
    let setLine: String
    let panelAccessibilityIdentifier: String
    let titleAccessibilityIdentifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZoomableCardArtwork(
                url: enlargedImageURL ?? previewImageURL,
                width: CardPreviewMetrics.previewArtworkWidth,
                height: CardPreviewMetrics.previewArtworkHeight,
                cornerRadius: CardPreviewMetrics.previewCornerRadius
            )
            .frame(
                width: CardPreviewMetrics.previewArtworkWidth,
                height: CardPreviewMetrics.previewArtworkHeight
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.primaryText)
                    .accessibilityIdentifier(titleAccessibilityIdentifier)

                if typeLine.isEmpty == false {
                    Text(typeLine)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.palette.secondaryText)
                }

                Text(setLine)
                    .font(.caption)
                    .foregroundStyle(theme.palette.tertiaryText)
            }
        }
        .workshopPanel(.panel, cornerRadius: 20, padding: 18)
        .accessibilityIdentifier(panelAccessibilityIdentifier)
        .frame(width: CardPreviewMetrics.previewPanelWidth)
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}

struct CardArtworkContent: View {
    @Environment(\.colorScheme) private var colorScheme

    let url: URL?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        CachedCardAsyncImage(url: url) { image in
            image
                .interpolation(.high)
                .antialiased(true)
                .resizable()
                .scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.palette.insetPanel)
                .overlay {
                    ProgressView()
                }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(theme.palette.divider.opacity(0.7), lineWidth: 1)
        }
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}

private struct ZoomableCardArtwork: NSViewRepresentable {
    @Environment(\.appServices) private var services
    @Environment(AppPreferences.self) private var appPreferences

    let url: URL?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(
            hostingView: NSHostingView(
                rootView: cardArtworkContent
            )
        )
    }

    func makeNSView(context: Context) -> ZoomableCardScrollView {
        let viewportSize = NSSize(width: width, height: height)
        let scrollView = ZoomableCardScrollView(viewportSize: viewportSize)
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 1
        scrollView.maxMagnification = 5

        let hostingView = context.coordinator.hostingView
        hostingView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        scrollView.documentView = hostingView
        scrollView.resetViewport()
        return scrollView
    }

    func updateNSView(_ scrollView: ZoomableCardScrollView, context: Context) {
        let hostingView = context.coordinator.hostingView
        hostingView.rootView = cardArtworkContent
        hostingView.frame = CGRect(x: 0, y: 0, width: width, height: height)

        if scrollView.documentView !== hostingView {
            scrollView.documentView = hostingView
            scrollView.resetViewport()
        }

        scrollView.viewportSize = NSSize(width: width, height: height)
        scrollView.minMagnification = 1
        scrollView.maxMagnification = 5
    }

    private var cardArtworkContent: AnyView {
        AnyView(
            CardArtworkContent(
                url: url,
                width: width,
                height: height,
                cornerRadius: cornerRadius
            )
            .environment(\.appServices, services)
            .environment(appPreferences)
        )
    }

    final class Coordinator {
        let hostingView: NSHostingView<AnyView>

        init(hostingView: NSHostingView<AnyView>) {
            self.hostingView = hostingView
        }
    }
}

private final class ZoomableCardScrollView: NSScrollView {
    var viewportSize: NSSize {
        didSet {
            guard viewportSize != oldValue else { return }
            invalidateIntrinsicContentSize()
            frame.size = viewportSize
            contentView.setFrameSize(viewportSize)
        }
    }

    override var intrinsicContentSize: NSSize {
        viewportSize
    }

    init(viewportSize: NSSize) {
        self.viewportSize = viewportSize
        super.init(frame: CGRect(origin: .zero, size: viewportSize))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetViewport() {
        magnification = 1
        contentView.scroll(to: .zero)
        reflectScrolledClipView(contentView)
    }

    override func scrollWheel(with event: NSEvent) {
        guard event.modifierFlags.contains(.command) else {
            super.scrollWheel(with: event)
            return
        }

        let deltaY = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.scrollingDeltaY * 8
        guard deltaY != 0 else { return }

        let zoomFactor = pow(1.08, deltaY / 10)
        let proposedMagnification = magnification * zoomFactor
        let clampedMagnification = min(maxMagnification, max(minMagnification, proposedMagnification))
        guard abs(clampedMagnification - magnification) > 0.001 else { return }

        let documentPoint = documentView?.convert(event.locationInWindow, from: nil)
            ?? CGPoint(x: bounds.midX, y: bounds.midY)
        setMagnification(clampedMagnification, centeredAt: documentPoint)
    }
}
