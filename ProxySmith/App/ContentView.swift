import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings
    @Environment(AppPreferences.self) private var appPreferences

    @Query(sort: [SortDescriptor(\Deck.updatedAt, order: .reverse)])
    private var decks: [Deck]

    @State private var selectedDeckID: UUID?
    @State private var pendingDeckDeletion: Deck?

    var body: some View {
        NavigationSplitView {
            DeckSidebarView(
                decks: decks,
                selectedDeckID: $selectedDeckID,
                onCreateDeck: createDeck,
                onDeleteSelectedDeck: requestDeleteSelectedDeck,
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

                Button(role: .destructive, action: requestDeleteSelectedDeck) {
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
        .confirmationDialog(
            "Delete \"\(pendingDeckDeletion?.name ?? "Deck")\"?",
            isPresented: Binding(
                get: { pendingDeckDeletion != nil },
                set: { if $0 == false { pendingDeckDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Deck", role: .destructive) {
                confirmDeleteSelectedDeck()
            }
            Button("Cancel", role: .cancel) {
                pendingDeckDeletion = nil
            }
        } message: {
            Text("\(pendingDeckDeletion?.name ?? "This deck") and all of its cards will be removed from ProxySmith.")
        }
        .onAppear {
            seedUITestDeckIfNeeded()
            if selectedDeckID == nil {
                selectedDeckID = decks.first?.id
            }
        }
        .onChange(of: decks) { _, decks in
            if let selectedDeckID,
               decks.contains(where: { $0.id == selectedDeckID }) == false {
                self.selectedDeckID = decks.first?.id
            } else if self.selectedDeckID == nil {
                self.selectedDeckID = decks.first?.id
            }
        }
    }

    private var selectedDeck: Deck? {
        guard let selectedDeckID else { return nil }
        return decks.first(where: { $0.id == selectedDeckID })
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

        selectedDeckID = deck.id
    }

    private func requestDeleteSelectedDeck() {
        guard let selectedDeck else { return }
        pendingDeckDeletion = selectedDeck
    }

    private func confirmDeleteSelectedDeck() {
        guard let pendingDeckDeletion else { return }
        guard decks.contains(pendingDeckDeletion) else {
            self.pendingDeckDeletion = nil
            return
        }

        let nextSelectedDeck = decks.first(where: { $0.id != pendingDeckDeletion.id })
        modelContext.delete(pendingDeckDeletion)
        try? modelContext.save()
        selectedDeckID = nextSelectedDeck?.id
        self.pendingDeckDeletion = nil
    }

    private func seedUITestDeckIfNeeded() {
        guard LaunchConfiguration.shouldSeedSampleDeck, decks.isEmpty else { return }

        let deck = LaunchConfiguration.makeUITestSampleDeck()
        modelContext.insert(deck)
        try? modelContext.save()
        selectedDeckID = deck.id
    }
}
