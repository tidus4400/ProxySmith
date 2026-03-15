import AppKit
import SwiftUI

struct DeckCardRowView: View {
    private let cardCornerRadius: CGFloat = 6

    @Bindable var card: DeckCard
    @State private var isShowingCardPreview = false

    let onDelete: () -> Void
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Button {
                isShowingCardPreview.toggle()
            } label: {
                cardArtwork(
                    url: card.previewImageURL ?? card.printImageURL,
                    width: 84,
                    height: 116,
                    cornerRadius: cardCornerRadius
                )
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Preview \(card.name)")
            .accessibilityIdentifier("deck-card-preview-button-\(card.scryfallID)")
            .popover(isPresented: $isShowingCardPreview, arrowEdge: .leading) {
                cardPreviewPopover
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(card.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if card.manaCost.isEmpty == false {
                    Text(card.manaCost)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                if card.typeLine.isEmpty == false {
                    Text(card.typeLine)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                }

                Text(card.setLine)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Text("Qty \(card.quantity)x")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.white.opacity(0.12))
                    )
                    .accessibilityIdentifier("deck-card-quantity-badge")

                Stepper(value: Binding(
                    get: { card.quantity },
                    set: { newValue in
                        card.quantity = max(1, newValue)
                        onChange()
                    }
                ), in: 1 ... 99) {
                    Text("Quantity")
                }
                .labelsHidden()
            }
            .frame(width: 110)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("deck-card-row-\(card.scryfallID)")
        .glassPanel(cornerRadius: 26, padding: 16)
    }

    private var cardPreviewPopover: some View {
        ZStack {
            AppBackgroundView()

            VStack(alignment: .leading, spacing: 14) {
                ZoomableCardArtwork(
                    url: card.printImageURL ?? card.previewImageURL,
                    width: 362,
                    height: 504,
                    cornerRadius: 21
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("deck-card-preview-title-\(card.scryfallID)")

                    if card.typeLine.isEmpty == false {
                        Text(card.typeLine)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.76))
                    }

                    Text(card.setLine)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            .padding(20)
            .accessibilityIdentifier("deck-card-preview-panel-\(card.scryfallID)")
        }
        .frame(width: 410)
    }

    private func cardArtwork(
        url: URL?,
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat
    ) -> some View {
        CardArtworkContent(
            url: url,
            width: width,
            height: height,
            cornerRadius: cornerRadius
        )
    }
}

private struct CardArtworkContent: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .interpolation(.high)
                .antialiased(true)
                .resizable()
                .scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay {
                    ProgressView()
                }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct ZoomableCardArtwork: NSViewRepresentable {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(
            hostingView: NSHostingView(
                rootView: CardArtworkContent(
                    url: url,
                    width: width,
                    height: height,
                    cornerRadius: cornerRadius
                )
            )
        )
    }

    func makeNSView(context: Context) -> ZoomableCardScrollView {
        let scrollView = ZoomableCardScrollView()
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
        scrollView.magnification = 1
        return scrollView
    }

    func updateNSView(_ scrollView: ZoomableCardScrollView, context: Context) {
        let hostingView = context.coordinator.hostingView
        hostingView.rootView = CardArtworkContent(
            url: url,
            width: width,
            height: height,
            cornerRadius: cornerRadius
        )
        hostingView.frame = CGRect(x: 0, y: 0, width: width, height: height)

        if scrollView.documentView !== hostingView {
            scrollView.documentView = hostingView
        }

        scrollView.minMagnification = 1
        scrollView.maxMagnification = 5
    }

    final class Coordinator {
        let hostingView: NSHostingView<CardArtworkContent>

        init(hostingView: NSHostingView<CardArtworkContent>) {
            self.hostingView = hostingView
        }
    }
}

private final class ZoomableCardScrollView: NSScrollView {
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
