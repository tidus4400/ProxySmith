import AppKit
import SwiftData
import SwiftUI

struct DeckWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appServices) private var services
    @Environment(AppPreferences.self) private var appPreferences
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var deck: Deck

    @State private var isShowingSearchSheet = false
    @State private var isShowingPreviewSheet = false
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
        .sheet(isPresented: $isShowingPreviewSheet) {
            PDFPreviewSheet(
                snapshot: deck.exportSnapshot,
                pdfExportService: services.pdfExportService,
                imageRepository: services.imageRepository
            )
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
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(theme.palette.secondaryText)
                    .textCase(.uppercase)

                TextField("Deck Name", text: $deck.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 35, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.primaryText)
                    .accessibilityIdentifier("deck-name-field")

                Text("Search Scryfall, collect the exact cards you want, then export print-ready A4 proxy sheets.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.palette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    metricTile(title: "Cards", value: "\(deck.totalCardCount)")
                    metricTile(title: "Pages", value: "\(PrintLayout.pageCount(forCardCount: deck.totalCardCount))")
                }

                HStack(spacing: 12) {
                    addCardsButton
                    if deck.cards.isEmpty == false {
                        Text(deck.sheetCornerStyle.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.palette.highlight)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(theme.palette.raisedPanel)
                            )
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(theme.palette.divider.opacity(0.8), lineWidth: 1)
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .workshopPanel(.panel, cornerRadius: 24, padding: 24)

            VStack(alignment: .leading, spacing: 18) {
                Text("Print Inspector")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.primaryText)

                inspectorControlGroup(
                    title: "Print Scale",
                    value: "\(Int(deck.scalePercent))%"
                ) {
                    Slider(value: $deck.scalePercent, in: 80 ... 100, step: 1)
                        .tint(theme.palette.primaryAction)
                } description: {
                    Text("100% matches real MTG card size. Drop to 90% for sleeve inserts with a backing card.")
                }

                Divider()
                    .overlay(theme.palette.divider.opacity(0.7))

                inspectorControlGroup(
                    title: "Bleed",
                    value: bleedValueText,
                    valueAccessibilityIdentifier: "deck-bleed-value"
                ) {
                    Slider(
                        value: Binding(
                            get: { deck.bleedMillimeters },
                            set: { deck.bleedMillimeters = roundBleed($0) }
                        ),
                        in: 0 ... PrintLayout.maximumBleedMillimeters,
                        step: 0.1
                    )
                    .tint(theme.palette.supportAction)
                    .accessibilityIdentifier("deck-bleed-slider")
                } description: {
                    Text("Adds 0.0 mm to 2.0 mm of edge-matched bleed on every side so neighboring cards split the gap with their own sampled border colors while cut guides stay on the final trim line.")
                }

                Divider()
                    .overlay(theme.palette.divider.opacity(0.7))

                inspectorControlGroup(
                    title: "Sheet Corners",
                    value: deck.sheetCornerStyle.displayName,
                    valueAccessibilityIdentifier: "deck-sheet-corner-style-value"
                ) {
                    Picker(
                        "Sheet Corners",
                        selection: Binding(
                            get: { deck.sheetCornerStyle },
                            set: { deck.sheetCornerStyle = $0 }
                        )
                    ) {
                        ForEach(SheetCornerStyle.allCases, id: \.self) { style in
                            Text(style.displayName)
                                .tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("deck-sheet-corner-style-picker")
                } description: {
                    Text("Choose whether cards keep rounded source-style corners on the sheet or render with straight corners in preview and export.")
                }

                Divider()
                    .overlay(theme.palette.divider.opacity(0.7))

                VStack(spacing: 10) {
                    Button {
                        isShowingPreviewSheet = true
                    } label: {
                        buttonLabel(title: "Preview Sheets", systemImage: "doc.text.magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .appButtonStyle(.secondary)
                    .disabled(deck.cards.isEmpty || isExporting)
                    .opacity(deck.cards.isEmpty || isExporting ? 0.55 : 1)
                    .accessibilityIdentifier("deck-preview-sheets-button")

                    Button {
                        Task { await exportDeck() }
                    } label: {
                        buttonLabel(
                            title: isExporting ? "Exporting..." : "Export Print Sheets",
                            systemImage: "printer.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .appButtonStyle(.primary)
                    .disabled(deck.cards.isEmpty || isExporting)
                    .accessibilityIdentifier("deck-export-sheets-button")
                }
            }
            .frame(width: 320, alignment: .leading)
            .workshopPanel(.rail, cornerRadius: 22, padding: 20)
        }
        .onChange(of: deck.name) { _, _ in
            deck.touch()
        }
        .onChange(of: deck.scalePercent) { _, _ in
            deck.touch()
        }
        .onChange(of: deck.bleedMillimeters) { _, _ in
            deck.touch()
        }
        .onChange(of: deck.sheetCornerStyleRawValue) { _, _ in
            deck.touch()
        }
    }

    private var emptyDeckPanel: some View {
        VStack(spacing: 18) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 46))
                .foregroundStyle(theme.palette.highlight)

            Text("This deck is empty")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.primaryText)

            Text("Use Add Cards to search Scryfall and start assembling the print run.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .workshopPanel(.panel, cornerRadius: 24, padding: 34)
    }

    private var cardListPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Deck List")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.primaryText)
                Spacer()
                Text("\(deck.cards.count) unique")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.palette.secondaryText)
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
        .workshopPanel(.panel, cornerRadius: 24, padding: 22)
    }

    private var addCardsButton: some View {
        Button {
            isShowingSearchSheet = true
        } label: {
            buttonLabel(title: "Add Cards", systemImage: "plus.viewfinder")
        }
        .appButtonStyle(.support)
        .accessibilityIdentifier("deck-add-cards-button")
        .popover(isPresented: $isShowingSearchSheet, arrowEdge: .top) {
            CardSearchSheet(deck: deck)
        }
    }

    private func buttonLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.palette.secondaryText)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .workshopPanel(.raised, cornerRadius: 16, padding: 14)
    }

    private func inspectorControlGroup<Control: View, Description: View>(
        title: String,
        value: String,
        valueAccessibilityIdentifier: String? = nil,
        @ViewBuilder control: () -> Control,
        @ViewBuilder description: () -> Description
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.palette.primaryText)
                Spacer()
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.palette.secondaryText)
                    .monospacedDigit()
                    .modifier(OptionalAccessibilityIdentifier(accessibilityIdentifier: valueAccessibilityIdentifier))
            }

            control()

            description()
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.palette.tertiaryText)
        }
    }

    private var bleedValueText: String {
        String(
            format: "%.1f mm",
            locale: Locale(identifier: "en_US_POSIX"),
            deck.bleedMillimeters
        )
    }

    private func roundBleed(_ value: Double) -> Double {
        let clampedValue = max(0, min(value, PrintLayout.maximumBleedMillimeters))
        return (clampedValue * 10).rounded() / 10
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
                imageRepository: services.imageRepository,
                cacheLifetime: appPreferences.cardImageCacheLifetime
            )
            deck.touch()
            try? modelContext.save()
        } catch {
            exportErrorMessage = error.localizedDescription
        }

        isExporting = false
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}

private struct OptionalAccessibilityIdentifier: ViewModifier {
    let accessibilityIdentifier: String?

    func body(content: Content) -> some View {
        if let accessibilityIdentifier {
            content.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            content
        }
    }
}
