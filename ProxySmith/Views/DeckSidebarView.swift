import SwiftUI

struct DeckSidebarView: View {
    @Environment(\.colorScheme) private var colorScheme

    let decks: [Deck]
    @Binding var selectedDeckID: UUID?
    let onCreateDeck: () -> Void
    let onDeleteSelectedDeck: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ProxySmith")
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.palette.primaryText)

                        Text("Deck-first proxy layout for fast A4 print sheets.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.palette.secondaryText)

                        HStack(spacing: 8) {
                            Label("Workshop", systemImage: "shippingbox")
                            Text("\(decks.count) decks")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.palette.highlight)
                    }

                    List(selection: $selectedDeckID) {
                        ForEach(decks) { deck in
                            DeckSidebarRow(deck: deck)
                                .tag(deck.id)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.sidebar)
                    .frame(maxHeight: .infinity)

                    VStack(spacing: 12) {
                        Button(action: onCreateDeck) {
                            Label("New Deck", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .appButtonStyle(.primary)
                        .accessibilityIdentifier("sidebar-new-deck-button")

                        HStack(spacing: 12) {
                            Button(role: .destructive, action: onDeleteSelectedDeck) {
                                Label("Delete Deck", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .appButtonStyle(.destructive)
                            .accessibilityIdentifier("sidebar-delete-deck-button")
                            .disabled(selectedDeckID == nil)

                            Button(action: onOpenSettings) {
                                Label("Settings", systemImage: "gearshape")
                                    .frame(maxWidth: .infinity)
                            }
                            .appButtonStyle(.secondary)
                            .accessibilityIdentifier("sidebar-open-settings-button")
                        }
                    }
                    .workshopPanel(.raised, cornerRadius: 18, padding: 16)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .workshopPanel(.rail, cornerRadius: 24, padding: 20)
                .padding(20)
            }
        }
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}

private struct DeckSidebarRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(deck.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.palette.primaryText)
                .lineLimit(1)

            HStack(spacing: 8) {
                Label("\(deck.totalCardCount)", systemImage: "square.stack.3d.down.right")
                Text("\(Int(deck.scalePercent))%")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(theme.palette.secondaryText)
        }
        .padding(.vertical, 6)
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}
