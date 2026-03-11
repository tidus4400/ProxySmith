import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Deck.updatedAt, order: .reverse)])
    private var decks: [Deck]

    @State private var selectedDeck: Deck?

    var body: some View {
        NavigationSplitView {
            DeckSidebarView(
                decks: decks,
                selectedDeck: $selectedDeck,
                onCreateDeck: createDeck,
                onDeleteSelectedDeck: deleteSelectedDeck
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320)
        } detail: {
            Group {
                if let selectedDeck {
                    DeckWorkspaceView(deck: selectedDeck)
                } else {
                    EmptyLibraryView(createDeck: createDeck)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppBackgroundView())
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: createDeck) {
                    Label("New Deck", systemImage: "plus")
                }

                Button(role: .destructive, action: deleteSelectedDeck) {
                    Label("Delete Deck", systemImage: "trash")
                }
                .disabled(selectedDeck == nil)
            }
        }
        .onAppear {
            if selectedDeck == nil {
                selectedDeck = decks.first
            }
        }
        .onChange(of: decks) { _, decks in
            if let selectedDeck, decks.contains(selectedDeck) == false {
                self.selectedDeck = decks.first
            } else if self.selectedDeck == nil {
                self.selectedDeck = decks.first
            }
        }
    }

    private func createDeck() {
        let deck = Deck(name: nextDeckName())
        modelContext.insert(deck)
        try? modelContext.save()
        selectedDeck = deck
    }

    private func deleteSelectedDeck() {
        guard let selectedDeck else { return }
        modelContext.delete(selectedDeck)
        try? modelContext.save()
        self.selectedDeck = decks.first(where: { $0.id != selectedDeck.id })
    }

    private func nextDeckName() -> String {
        let baseName = "Untitled Deck"
        let existingNames = Set(decks.map(\.name))
        guard existingNames.contains(baseName) else { return baseName }

        var index = 2
        while existingNames.contains("\(baseName) \(index)") {
            index += 1
        }

        return "\(baseName) \(index)"
    }
}

