import AppKit
import SwiftData
import SwiftUI

struct DeckWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appServices) private var services

    @Bindable var deck: Deck

    @State private var isShowingSearchSheet = false
    @State private var isExporting = false
    @State private var exportErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroPanel

                if deck.cards.isEmpty {
                    emptyDeckPanel
                } else {
                    cardListPanel
                }
            }
            .padding(28)
        }
        .background(AppBackgroundView())
        .sheet(isPresented: $isShowingSearchSheet) {
            CardSearchSheet(deck: deck)
        }
        .alert("Export Failed", isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { if $0 == false { exportErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    private var heroPanel: some View {
        HStack(alignment: .top, spacing: 22) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Deck Workspace")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .textCase(.uppercase)

                TextField("Deck Name", text: $deck.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Search Scryfall, collect the exact cards you want, then export print-ready A4 proxy sheets.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.76))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    actionButton(
                        title: "Add Cards",
                        systemImage: "plus.viewfinder",
                        tint: Color(red: 0.33, green: 0.76, blue: 0.73)
                    ) {
                        isShowingSearchSheet = true
                    }

                    actionButton(
                        title: isExporting ? "Exporting..." : "Export Print Sheets",
                        systemImage: "printer.fill",
                        tint: Color(red: 0.95, green: 0.55, blue: 0.28),
                        action: { Task { await exportDeck() } }
                    )
                    .disabled(deck.cards.isEmpty || isExporting)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 18) {
                metricRow(title: "Cards", value: "\(deck.totalCardCount)")
                metricRow(title: "Pages", value: "\(PrintLayout.pageCount(forCardCount: deck.totalCardCount))")
                metricRow(title: "Card Scale", value: "\(Int(deck.scalePercent))%")

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Print Scale")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("\(Int(deck.scalePercent))%")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $deck.scalePercent, in: 80 ... 100, step: 1)
                        .tint(Color(red: 0.95, green: 0.55, blue: 0.28))

                    Text("100% matches real MTG card size. Drop to 90% for sleeve inserts with a backing card.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 320, alignment: .leading)
            .glassPanel(cornerRadius: 30, padding: 20)
        }
        .glassPanel(cornerRadius: 36, padding: 26)
        .onChange(of: deck.name) { _, _ in
            deck.touch()
        }
        .onChange(of: deck.scalePercent) { _, _ in
            deck.touch()
        }
    }

    private var emptyDeckPanel: some View {
        VStack(spacing: 18) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 46))
                .foregroundStyle(.white.opacity(0.88))

            Text("This deck is empty")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Use Add Cards to search Scryfall and start assembling the print run.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.76))
        }
        .frame(maxWidth: .infinity)
        .glassPanel(cornerRadius: 34, padding: 34)
    }

    private var cardListPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Deck List")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(deck.cards.count) unique")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }

            LazyVStack(spacing: 14) {
                ForEach(deck.sortedCards) { card in
                    DeckCardRowView(card: card) {
                        removeCard(card)
                    } onChange: {
                        deck.touch()
                        try? modelContext.save()
                    }
                }
            }
        }
        .glassPanel(cornerRadius: 34, padding: 24)
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.primary)
    }

    private func removeCard(_ card: DeckCard) {
        modelContext.delete(card)
        deck.touch()
        try? modelContext.save()
    }

    @MainActor
    private func exportDeck() async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(deck.name.replacingOccurrences(of: "/", with: "-"))-sheets.pdf"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        isExporting = true
        let snapshot = deck.exportSnapshot

        do {
            try await services.pdfExportService.export(
                snapshot: snapshot,
                to: url,
                imageRepository: services.imageRepository
            )
            deck.touch()
            try? modelContext.save()
        } catch {
            exportErrorMessage = error.localizedDescription
        }

        isExporting = false
    }
}

