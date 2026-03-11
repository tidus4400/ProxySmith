import SwiftUI

struct DeckCardRowView: View {
    @Bindable var card: DeckCard

    let onDelete: () -> Void
    let onChange: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            AsyncImage(url: card.previewImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .overlay {
                        ProgressView()
                    }
            }
            .frame(width: 84, height: 116)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
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

            Stepper(value: Binding(
                get: { card.quantity },
                set: { newValue in
                    card.quantity = max(1, newValue)
                    onChange()
                }
            ), in: 1 ... 99) {
                Text("\(card.quantity)x")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minWidth: 44)
            }
            .labelsHidden()
            .frame(width: 110)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
        }
        .glassPanel(cornerRadius: 26, padding: 16)
    }
}

