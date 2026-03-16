import SwiftData
import SwiftUI

struct SettingsView: View {
    let onSaveCardImageCacheDirectory: () -> Void

    @Environment(AppPreferences.self) private var appPreferences

    @Query(sort: [SortDescriptor(\Deck.createdAt, order: .forward)])
    private var decks: [Deck]

    @State private var isShowingResetAlert = false
    @State private var cacheFolderDraft = ""
    @State private var pendingCacheFolderDraft = ""
    @State private var pendingCacheFolderDescription = ""
    @State private var isShowingCacheFolderSaveConfirmation = false
    @State private var isShowingCacheFolderError = false
    @State private var cacheFolderErrorMessage = ""

    init(onSaveCardImageCacheDirectory: @escaping () -> Void = {}) {
        self.onSaveCardImageCacheDirectory = onSaveCardImageCacheDirectory
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerPanel
                    numberingPanel
                    imageCachePanel
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
        .confirmationDialog("Save Cache Folder?", isPresented: $isShowingCacheFolderSaveConfirmation, titleVisibility: .visible) {
            Button("Save") {
                saveCacheFolder()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("ProxySmith will store card art in `\(pendingCacheFolderDescription)` after this change is saved.")
        }
        .alert("Invalid Cache Folder", isPresented: $isShowingCacheFolderError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cacheFolderErrorMessage)
        }
        .onAppear {
            resetCacheFolderDraft()
        }
        .onDisappear {
            resetCacheFolderDraft()
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Options")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Control ProxySmith’s deck numbering and how long Scryfall card images stay cached before the app refreshes them.")
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

    private var imageCachePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Card Image Cache")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Stepper(
                value: Binding(
                    get: { appPreferences.cardImageCachePeriodDays },
                    set: { appPreferences.cardImageCachePeriodDays = $0 }
                ),
                in: 1 ... 365
            ) {
                HStack(alignment: .center, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Image Cache TTL")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("How long ProxySmith keeps downloaded Scryfall art before refreshing it from the network.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(appPreferences.cardImageCachePeriodDays)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.98, green: 0.80, blue: 0.44))
                            .monospacedDigit()

                        Text(appPreferences.cardImageCachePeriodDays == 1 ? "Day" : "Days")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(18)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityIdentifier("card-image-cache-period-stepper")

            Divider()
                .overlay(.white.opacity(0.14))

            imageCacheFolderEditor

            HStack(alignment: .top, spacing: 16) {
                settingsMetric(
                    title: "Refresh After",
                    value: "\(appPreferences.cardImageCachePeriodDays) \(appPreferences.cardImageCachePeriodDays == 1 ? "Day" : "Days")",
                    accessibilityIdentifier: "card-image-cache-period-value"
                )

                settingsMetric(
                    title: "Saved Folder",
                    value: appPreferences.cardImageCacheLocationDescription,
                    accessibilityIdentifier: "card-image-cache-location-value"
                )

                settingsMetric(
                    title: "Settings File",
                    value: appPreferences.settingsFileLocationDescription
                )
            }

            Text("Scryfall recommends caching downloaded data for at least 24 hours, and their gameplay updates are usually sparse enough that weekly refreshes are often sufficient. ProxySmith defaults to a 7 day TTL for card art, but you can tune it here.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
        }
        .glassPanel(cornerRadius: 32, padding: 24)
    }

    private var imageCacheFolderEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Image Cache Folder")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Enter an absolute path or a `~/` path, then save and confirm the change.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer(minLength: 12)

                Button("Save Folder") {
                    confirmCacheFolderSave()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.96, green: 0.63, blue: 0.22))
                .disabled(cacheFolderDraft.trimmingCharacters(in: .whitespacesAndNewlines) == appPreferences.cardImageCacheDirectoryInput)
                .accessibilityIdentifier("save-card-image-cache-folder-button")
            }

            TextField("~/.proxysmith/cache/card-images", text: $cacheFolderDraft)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .accessibilityIdentifier("card-image-cache-folder-field")

            Text("Leave the field blank to restore the default cache location under `~/.proxysmith/cache/card-images`.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
        .padding(18)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var effectiveNextGlobalDeckNumber: Int {
        DeckNameGenerator.nextGlobalDeckNumber(
            existingNames: decks.map(\.name),
            storedNextGlobalDeckNumber: appPreferences.nextGlobalDeckNumber
        )
    }

    private func confirmCacheFolderSave() {
        do {
            let resolvedDirectory = try appPreferences.previewCardImageCacheDirectory(for: cacheFolderDraft)
            pendingCacheFolderDraft = cacheFolderDraft
            pendingCacheFolderDescription = resolvedDirectory.pathRelativeToHome()
            isShowingCacheFolderSaveConfirmation = true
        } catch {
            cacheFolderErrorMessage = error.localizedDescription
            isShowingCacheFolderError = true
        }
    }

    private func saveCacheFolder() {
        do {
            try appPreferences.saveCardImageCacheDirectory(from: pendingCacheFolderDraft)
            cacheFolderDraft = appPreferences.cardImageCacheDirectoryInput
            onSaveCardImageCacheDirectory()
        } catch {
            cacheFolderErrorMessage = error.localizedDescription
            isShowingCacheFolderError = true
        }
    }

    private func resetCacheFolderDraft() {
        cacheFolderDraft = appPreferences.cardImageCacheDirectoryInput
        pendingCacheFolderDraft = ""
        pendingCacheFolderDescription = ""
        isShowingCacheFolderSaveConfirmation = false
        isShowingCacheFolderError = false
        cacheFolderErrorMessage = ""
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
