import SwiftData
import SwiftUI

struct CardSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appServices) private var services

    let deck: Deck

    @State private var query = ""
    @State private var results: [ScryfallCard] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var addedCardIDs = Set<String>()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add Cards")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Search by card name or Scryfall syntax. Results are throttled to stay API-friendly.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.76))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassPanel(cornerRadius: 30, padding: 20)

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.68))

                        TextField("Search cards", text: $query)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("card-search-field")

                        if isSearching {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .glassPanel(cornerRadius: 24, padding: 0)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassPanel(cornerRadius: 24, padding: 16)
                    }

                    Group {
                        if results.isEmpty {
                            ContentUnavailableView(
                                query.count < 2 ? "Start typing a card name" : "No cards found",
                                systemImage: "rectangle.and.text.magnifyingglass",
                                description: Text(query.count < 2 ? "Enter at least two characters to search Scryfall." : "Try a broader name or a different Scryfall query.")
                            )
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 14) {
                                    ForEach(results) { card in
                                        SearchResultCardView(
                                            card: card,
                                            wasAdded: addedCardIDs.contains(card.id),
                                            onAdd: { add(card) }
                                        )
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .glassPanel(cornerRadius: 30, padding: 20)
                }
                .padding(24)
            }
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityIdentifier("card-search-close-button")
                }
            }
        }
        .frame(minWidth: 860, minHeight: 720)
        .task(id: query) {
            await search()
        }
    }

    @MainActor
    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            try await Task.sleep(for: .milliseconds(350))
            guard Task.isCancelled == false else { return }
            results = try await services.scryfallClient.searchCards(query: trimmed)
        } catch is CancellationError {
            return
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    private func add(_ card: ScryfallCard) {
        deck.addCard(from: card)
        addedCardIDs.insert(card.id)
        try? modelContext.save()
    }
}

private struct SearchResultCardView: View {
    let card: ScryfallCard
    let wasAdded: Bool
    let onAdd: () -> Void

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
            .frame(width: 82, height: 114)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(card.displayName)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if card.displayManaCost.isEmpty == false {
                    Text(card.displayManaCost)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                if card.displayTypeLine.isEmpty == false {
                    Text(card.displayTypeLine)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }

                Text("\(card.set.uppercased()) • \(card.collectorNumber) • \(card.rarity.capitalized)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            Button(action: onAdd) {
                Label(wasAdded ? "Added" : "Add", systemImage: wasAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
            .tint(wasAdded ? Color(red: 0.33, green: 0.76, blue: 0.73) : Color(red: 0.95, green: 0.55, blue: 0.28))
        }
        .glassPanel(cornerRadius: 26, padding: 16)
    }
}
