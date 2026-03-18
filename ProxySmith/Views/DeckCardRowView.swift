import SwiftUI

struct DeckCardRowView: View {
    @Bindable var card: DeckCard

    let onDelete: () -> Void
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            CardPreviewButton(
                previewImageURL: card.previewImageURL,
                enlargedImageURL: card.printImageURL,
                title: card.name,
                typeLine: card.typeLine,
                setLine: card.setLine,
                thumbnailWidth: 84,
                thumbnailHeight: 116,
                accessibilityLabel: "Preview \(card.name)",
                buttonAccessibilityIdentifier: "deck-card-preview-button-\(card.scryfallID)",
                panelAccessibilityIdentifier: "deck-card-preview-panel-\(card.scryfallID)",
                titleAccessibilityIdentifier: "deck-card-preview-title-\(card.scryfallID)"
            )

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
}
