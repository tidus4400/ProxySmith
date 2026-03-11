import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(AppPreferences.self) private var appPreferences

    @Query(sort: [SortDescriptor(\Deck.createdAt, order: .forward)])
    private var decks: [Deck]

    @State private var isShowingResetAlert = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerPanel
                    numberingPanel
                    changelogPanel
                }
                .padding(24)
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .accessibilityIdentifier("settings-root")
        .alert("Reset Deck Counter?", isPresented: $isShowingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset") {
                appPreferences.resetDeckNumberCounter()
            }
        } message: {
            Text("The stored counter will return to 1. Existing untitled decks still reserve higher numbers while global numbering stays enabled.")
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Options")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Control how ProxySmith assigns default deck names and keeps the numbering sequence predictable.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 32, padding: 24)
    }

    private var numberingPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Deck Numbering")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Toggle(isOn: Binding(
                get: { appPreferences.globalDeckNumberingEnabled },
                set: { appPreferences.globalDeckNumberingEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Use Global Deck Numbers")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Enabled: deleted untitled deck numbers are never reused. Disabled: ProxySmith fills the lowest missing number instead.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .toggleStyle(.switch)
            .accessibilityIdentifier("global-deck-numbering-toggle")

            Divider()
                .overlay(.white.opacity(0.14))

            HStack(alignment: .top, spacing: 16) {
                settingsMetric(
                    title: "Next Global Number",
                    value: "\(effectiveNextGlobalDeckNumber)",
                    accessibilityIdentifier: "next-global-deck-number-value"
                )

                settingsMetric(
                    title: "Untitled Deck Preview",
                    value: DeckNameGenerator.name(for: effectiveNextGlobalDeckNumber)
                )

                settingsMetric(
                    title: "Highest Reserved Number",
                    value: "\(DeckNameGenerator.highestReservedDeckNumber(existingNames: decks.map(\.name)))"
                )
            }

            Text("Resetting the counter is safest after cleaning out old untitled decks. If numbered decks still exist, ProxySmith will continue above the highest reserved value.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))

            Button("Reset Deck Counter") {
                isShowingResetAlert = true
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("reset-deck-counter-button")
        }
        .glassPanel(cornerRadius: 32, padding: 24)
    }

    private var changelogPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delivery Rule")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Every commit should also update CHANGELOG.md. The agent context file now treats that as a workflow requirement, not an optional note.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 28, padding: 20)
    }

    private var effectiveNextGlobalDeckNumber: Int {
        DeckNameGenerator.nextGlobalDeckNumber(
            existingNames: decks.map(\.name),
            storedNextGlobalDeckNumber: appPreferences.nextGlobalDeckNumber
        )
    }

    private func settingsMetric(
        title: String,
        value: String,
        accessibilityIdentifier: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))

            if let accessibilityIdentifier {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .accessibilityIdentifier(accessibilityIdentifier)
            } else {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
