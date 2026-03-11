import SwiftUI

struct EmptyLibraryView: View {
    let createDeck: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("Start a Proxy Deck")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Create a deck, pull card art from Scryfall, and export print-ready A4 sheets at real card scale.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: 620)
            }

            Button(action: createDeck) {
                Label("Create Your First Deck", systemImage: "sparkles.rectangle.stack")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.95, green: 0.55, blue: 0.28))
        }
        .glassPanel(cornerRadius: 36, padding: 32)
        .padding(32)
    }
}

