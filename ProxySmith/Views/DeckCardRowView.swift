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
                cardArtwork(
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
