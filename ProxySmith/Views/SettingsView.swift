import AppKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    let onSaveCardImageCacheDirectory: () -> Void

    @Environment(AppPreferences.self) private var appPreferences
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: [SortDescriptor(\Deck.createdAt, order: .forward)])
    private var decks: [Deck]

    @State private var isShowingResetAlert = false
    @State private var cacheFolderDraft = ""
    @State private var pendingCacheFolderDraft = ""
    @State private var pendingCacheFolderDescription = ""
    @State private var isShowingCacheFolderSaveConfirmation = false
    @State private var isShowingCacheFolderError = false
    @State private var cacheFolderErrorMessage = ""
    @State private var settingsWindowObserver = SettingsWindowObserver()

    init(onSaveCardImageCacheDirectory: @escaping () -> Void = {}) {
        self.onSaveCardImageCacheDirectory = onSaveCardImageCacheDirectory
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerPanel
                    appearancePanel
                    numberingPanel
                    imageCachePanel
                }
                .padding(24)
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .accessibilityIdentifier("settings-root")
        .background(
            SettingsWindowAccessor { window in
                settingsWindowObserver.observe(
                    window: window,
                    onWindowAttached: resetCacheFolderDraft,
                    onWindowWillClose: resetCacheFolderDraft
                )
            }
        )
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
        .overlay(alignment: .topLeading) {
            AppAppearanceProbeView(accessibilityIdentifier: "settings-effective-appearance-probe")
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Options")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.primaryText)

            Text("Control ProxySmith’s appearance, deck numbering, and how long Scryfall card images stay cached before the app refreshes them.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .workshopPanel(.panel, cornerRadius: 22, padding: 22)
    }

    private var appearancePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Appearance")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.primaryText)

            Text("Choose whether ProxySmith follows macOS automatically or stays locked to a light or dark workspace.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.palette.secondaryText)

            HStack(alignment: .top, spacing: 12) {
                ForEach(AppAppearanceMode.allCases, id: \.self) { mode in
                    appearanceModeButton(mode)
                }
            }

            HStack(alignment: .top, spacing: 16) {
                settingsMetric(
                    title: "Saved Preference",
                    value: appPreferences.appearanceMode.displayName,
                    accessibilityIdentifier: "selected-appearance-mode-value"
                )

                settingsMetric(
                    title: "Active Appearance",
                    value: effectiveAppearanceMode.shortDisplayName,
                    accessibilityIdentifier: "effective-appearance-mode-value"
                )
            }

            Text("Sync with System updates both the library and Settings windows when macOS changes. Light and Dark override the system appearance immediately.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.palette.secondaryText)
        }
        .workshopPanel(.panel, cornerRadius: 22, padding: 22)
    }

    private var numberingPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Deck Numbering")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.primaryText)

            Toggle(isOn: Binding(
                get: { appPreferences.globalDeckNumberingEnabled },
                set: { appPreferences.globalDeckNumberingEnabled = $0 }
            )) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Use Global Deck Numbers")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.palette.primaryText)

                    Text("Enabled: deleted untitled deck numbers are never reused. Disabled: ProxySmith fills the lowest missing number instead.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.palette.secondaryText)
                }
            }
            .toggleStyle(.switch)
            .accessibilityIdentifier("global-deck-numbering-toggle")

            Divider()
                .overlay(theme.palette.divider.opacity(0.7))

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
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.palette.secondaryText)

            Button("Reset Deck Counter") {
                isShowingResetAlert = true
            }
            .appButtonStyle(.secondary)
            .accessibilityIdentifier("reset-deck-counter-button")
        }
        .workshopPanel(.panel, cornerRadius: 22, padding: 22)
    }

    private var imageCachePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Card Image Cache")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.palette.primaryText)

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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.palette.primaryText)

                        Text("How long ProxySmith keeps downloaded Scryfall art before refreshing it from the network.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.palette.secondaryText)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(appPreferences.cardImageCachePeriodDays)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.palette.highlight)
                            .monospacedDigit()

                        Text(appPreferences.cardImageCachePeriodDays == 1 ? "Day" : "Days")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.palette.secondaryText)
                    }
                }
            }
            .workshopPanel(.raised, cornerRadius: 16, padding: 18)
            .accessibilityIdentifier("card-image-cache-period-stepper")

            Divider()
                .overlay(theme.palette.divider.opacity(0.7))

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
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.palette.secondaryText)
        }
        .workshopPanel(.panel, cornerRadius: 22, padding: 22)
    }

    private var imageCacheFolderEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Image Cache Folder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.palette.primaryText)

                    Text("Enter an absolute path or a `~/` path, then save and confirm the change.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.palette.secondaryText)
                }

                Spacer(minLength: 12)

                Button("Save Folder") {
                    confirmCacheFolderSave()
                }
                .appButtonStyle(.primary)
                .disabled(cacheFolderDraft.trimmingCharacters(in: .whitespacesAndNewlines) == appPreferences.cardImageCacheDirectoryInput)
                .accessibilityIdentifier("save-card-image-cache-folder-button")
            }

            TextField("~/.proxysmith/cache/card-images", text: $cacheFolderDraft)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.palette.primaryText)
                .workshopInputField(cornerRadius: 14, fillStyle: .inset)
                .accessibilityIdentifier("card-image-cache-folder-field")

            Text("Leave the field blank to restore the default cache location under `~/.proxysmith/cache/card-images`.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.palette.tertiaryText)
        }
        .workshopPanel(.raised, cornerRadius: 16, padding: 18)
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.palette.secondaryText)

            if let accessibilityIdentifier {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .accessibilityIdentifier(accessibilityIdentifier)
            } else {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .workshopPanel(.raised, cornerRadius: 16, padding: 18)
    }

    private func appearanceModeButton(_ mode: AppAppearanceMode) -> some View {
        let isSelected = appPreferences.appearanceMode == mode
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        return Button {
            appPreferences.appearanceMode = mode
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(mode.shortDisplayName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Spacer(minLength: 8)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(mode.summary)
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(isSelected ? Color.white : theme.palette.primaryText)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(16)
            .background {
                shape.fill(isSelected ? theme.palette.primaryAction : theme.palette.raisedPanel)
            }
            .overlay {
                shape.stroke(
                    isSelected ? theme.palette.primaryAction.opacity(0.92) : theme.palette.divider.opacity(0.85),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("appearance-mode-\(mode.rawValue)-button")
    }

    private var effectiveAppearanceMode: AppAppearanceMode {
        switch appPreferences.appearanceMode {
        case .system:
            colorScheme == .dark ? .dark : .light
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    private var theme: AppTheme {
        AppTheme(colorScheme)
    }
}

private final class SettingsWindowObserver: @unchecked Sendable {
    private weak var observedWindow: NSWindow?
    private var didResignKeyObserver: NSObjectProtocol?
    private var willCloseObserver: NSObjectProtocol?
    private var onWindowAttached: () -> Void = {}
    private var onWindowWillClose: () -> Void = {}

    deinit {
        detach()
    }

    @MainActor
    func observe(
        window: NSWindow?,
        onWindowAttached: @escaping () -> Void,
        onWindowWillClose: @escaping () -> Void
    ) {
        guard observedWindow !== window else { return }

        detach()
        self.onWindowAttached = onWindowAttached
        self.onWindowWillClose = onWindowWillClose
        observedWindow = window

        guard let window else { return }

        onWindowAttached()

        let observedWindowNumber = window.windowNumber
        didResignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let window = self.observedWindow else { return }
                guard window.windowNumber == observedWindowNumber else { return }
                guard window.attachedSheet == nil else { return }
                window.close()
            }
        }

        willCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.onWindowWillClose()
                self.detach()
            }
        }
    }

    private func detach() {
        if let didResignKeyObserver {
            NotificationCenter.default.removeObserver(didResignKeyObserver)
            self.didResignKeyObserver = nil
        }

        if let willCloseObserver {
            NotificationCenter.default.removeObserver(willCloseObserver)
            self.willCloseObserver = nil
        }

        observedWindow = nil
    }
}

private struct SettingsWindowAccessor: NSViewRepresentable {
    let onWindowChange: (NSWindow?) -> Void

    func makeNSView(context: Context) -> WindowReportingView {
        let view = WindowReportingView()
        view.onWindowChange = onWindowChange
        return view
    }

    func updateNSView(_ nsView: WindowReportingView, context: Context) {
        nsView.onWindowChange = onWindowChange
        nsView.reportCurrentWindow()
    }
}

private final class WindowReportingView: NSView {
    var onWindowChange: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportCurrentWindow()
    }

    func reportCurrentWindow() {
        guard let onWindowChange else { return }

        Task { @MainActor [weak self] in
            onWindowChange(self?.window)
        }
    }
}
