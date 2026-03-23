import SwiftUI

struct EmptyLibraryView: View {
    @Environment(\.colorScheme) private var colorScheme

    let createDeck: () -> Void

    var body: some View {
        VStack {
            VStack(spacing: 24) {
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(theme.palette.highlight)

                VStack(spacing: 10) {
                    Text("Start a Proxy Deck")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.palette.primaryText)

                    Text("Create a deck, pull card art from Scryfall, and export print-ready A4 sheets at real card scale.")
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.palette.secondaryText)
                        .frame(maxWidth: 560)
                }

                Button(action: createDeck) {
                    Label("Create Your First Deck", systemImage: "plus.rectangle.on.folder")
                }
                .appButtonStyle(.primary)
                .accessibilityIdentifier("empty-state-new-deck-button")
            }
            .workshopPanel(.panel, cornerRadius: 24, padding: 34)
            .frame(maxWidth: 760)
            .padding(32)
        }
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}
