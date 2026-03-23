import SwiftData
import SwiftUI

struct CardSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appServices) private var services
    @Environment(\.colorScheme) private var colorScheme

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
                            .foregroundStyle(theme.palette.primaryText)

                        Text("Search by card name or Scryfall syntax. Results are throttled to stay API-friendly.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(theme.palette.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .workshopPanel(.panel, cornerRadius: 22, padding: 20)

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(theme.palette.secondaryText)

                        TextField("Search cards", text: $query)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(theme.palette.primaryText)
                            .accessibilityIdentifier("card-search-field")

                        if isSearching {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .workshopInputField(cornerRadius: 16, fillStyle: .raised)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.palette.destructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .workshopPanel(.raised, cornerRadius: 16, padding: 16)
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
                    .workshopPanel(.panel, cornerRadius: 22, padding: 20)
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

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}

private struct SearchResultCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let card: ScryfallCard
    let wasAdded: Bool
    let onAdd: () -> Void

    private var setLine: String {
        "\(card.set.uppercased()) • \(card.collectorNumber) • \(card.rarity.capitalized)"
    }

    var body: some View {
        HStack(spacing: 18) {
            CardPreviewButton(
                previewImageURL: card.previewImageURL,
                enlargedImageURL: card.printImageURL,
                title: card.displayName,
                typeLine: card.displayTypeLine,
                setLine: setLine,
                thumbnailWidth: 84,
                thumbnailHeight: 116,
                accessibilityLabel: "Preview \(card.displayName)",
                buttonAccessibilityIdentifier: "search-card-preview-button-\(card.id)",
                panelAccessibilityIdentifier: "search-card-preview-panel-\(card.id)",
                titleAccessibilityIdentifier: "search-card-preview-title-\(card.id)"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(card.displayName)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.primaryText)

                if card.displayManaCost.isEmpty == false {
                    Text(card.displayManaCost)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.palette.highlight)
                }

                if card.displayTypeLine.isEmpty == false {
                    Text(card.displayTypeLine)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.palette.secondaryText)
                }

                Text(setLine)
                    .font(.caption)
                    .foregroundStyle(theme.palette.tertiaryText)
            }

            Spacer()

            Button(action: onAdd) {
                Label(wasAdded ? "Added" : "Add", systemImage: wasAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .frame(width: 120)
            }
            .appButtonStyle(wasAdded ? .support : .primary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("search-card-row-\(card.id)")
        .workshopPanel(.raised, cornerRadius: 18, padding: 16)
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}
