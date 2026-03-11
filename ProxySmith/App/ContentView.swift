import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings
    @Environment(AppPreferences.self) private var appPreferences

    @Query(sort: [SortDescriptor(\Deck.updatedAt, order: .reverse)])
    private var decks: [Deck]

    @State private var selectedDeck: Deck?

    var body: some View {
        NavigationSplitView {
            DeckSidebarView(
                decks: decks,
                selectedDeck: $selectedDeck,
                onCreateDeck: createDeck,
                onDeleteSelectedDeck: deleteSelectedDeck,
                onOpenSettings: { openSettings() }
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
                .accessibilityIdentifier("toolbar-new-deck-button")

                Button(role: .destructive, action: deleteSelectedDeck) {
                    Label("Delete Deck", systemImage: "trash")
                }
                .accessibilityIdentifier("toolbar-delete-deck-button")
                .disabled(selectedDeck == nil)

                Button(action: { openSettings() }) {
                    Label("Options", systemImage: "gearshape")
                }
                .accessibilityIdentifier("toolbar-open-settings-button")
            }
        }
        .onAppear {
            seedUITestDeckIfNeeded()
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
        let generatedName = DeckNameGenerator.nextName(
            existingNames: decks.map(\.name),
            globalNumberingEnabled: appPreferences.globalDeckNumberingEnabled,
            storedNextGlobalDeckNumber: appPreferences.nextGlobalDeckNumber
        )

        let deck = Deck(name: generatedName.name)
        modelContext.insert(deck)
        try? modelContext.save()

        if appPreferences.globalDeckNumberingEnabled {
            appPreferences.nextGlobalDeckNumber = generatedName.updatedNextGlobalDeckNumber
        }

        selectedDeck = deck
    }

    private func deleteSelectedDeck() {
        guard let selectedDeck else { return }
        modelContext.delete(selectedDeck)
        try? modelContext.save()
        self.selectedDeck = decks.first(where: { $0.id != selectedDeck.id })
    }

    private func seedUITestDeckIfNeeded() {
        guard LaunchConfiguration.shouldSeedSampleDeck, decks.isEmpty else { return }

        let deck = LaunchConfiguration.makeUITestSampleDeck()
        modelContext.insert(deck)
        try? modelContext.save()
        selectedDeck = deck
    }
}
