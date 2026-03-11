import SwiftUI

struct DeckSidebarView: View {
    let decks: [Deck]
    @Binding var selectedDeck: Deck?
    let onCreateDeck: () -> Void
    let onDeleteSelectedDeck: () -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ProxySmith")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Deck-first proxy layout for fast A4 print sheets.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                }
                .glassPanel(cornerRadius: 30, padding: 20)

                List(selection: $selectedDeck) {
                    ForEach(decks) { deck in
                        DeckSidebarRow(deck: deck)
                            .tag(deck)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.sidebar)
                .glassPanel(cornerRadius: 30, padding: 8)

                HStack(spacing: 12) {
                    Button(action: onCreateDeck) {
                        Label("New Deck", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.33, green: 0.76, blue: 0.73))

                    Button(role: .destructive, action: onDeleteSelectedDeck) {
                        Image(systemName: "trash")
                            .frame(width: 32)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedDeck == nil)
                }
            }
            .padding(24)
        }
    }
}

private struct DeckSidebarRow: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(deck.name)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(1)

            HStack(spacing: 8) {
                Label("\(deck.totalCardCount)", systemImage: "square.stack.3d.down.right")
                Text("\(Int(deck.scalePercent))%")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

