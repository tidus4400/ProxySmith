import AppKit
import SwiftData
import SwiftUI

@main
struct ProxySmithApp: App {
    private let modelContainer: ModelContainer
    private let storageLayout: ProxySmithStorageLayout
    private let appPreferences: AppPreferences
    @State private var services: AppServices

    init() {
        do {
            storageLayout = LaunchConfiguration.makeStorageLayout()
            appPreferences = AppPreferences(storageLayout: storageLayout)
            _services = State(
                initialValue: AppServices.live(
                    storageLayout: storageLayout,
                    preferredCardImageCacheDirectory: appPreferences.cardImageCacheDirectory
                )
            )
            modelContainer = try ModelContainer(
                for: Deck.self,
                DeckCard.self,
                configurations: LaunchConfiguration.makeModelConfiguration()
            )
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        Window("ProxySmith", id: "main") {
            AppAppearanceRootView {
                ContentView()
                    .environment(\.appServices, services)
            }
                .environment(appPreferences)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 1480, height: 920)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)
        .commands {
            SidebarCommands()
        }

        Settings {
            AppAppearanceRootView {
                SettingsView {
                    services = AppServices.live(
                        storageLayout: storageLayout,
                        preferredCardImageCacheDirectory: appPreferences.cardImageCacheDirectory
                    )
                }
            }
                .environment(appPreferences)
        }
        .modelContainer(modelContainer)
    }
}

private struct AppAppearanceRootView<Content: View>: View {
    @Environment(AppPreferences.self) private var appPreferences

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background {
                AppAppearanceApplier(appearanceMode: appPreferences.appearanceMode)
                    .frame(width: 0, height: 0)
            }
    }
}

struct AppAppearanceProbeView: View {
    @Environment(\.colorScheme) private var colorScheme

    let accessibilityIdentifier: String

    var body: some View {
        Text(colorScheme == .dark ? "dark" : "light")
            .font(.caption2)
            .foregroundStyle(.clear)
            .opacity(0.001)
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct AppAppearanceApplier: NSViewRepresentable {
    let appearanceMode: AppAppearanceMode

    func makeNSView(context: Context) -> AppAppearanceApplyingView {
        let view = AppAppearanceApplyingView()
        view.appearanceMode = appearanceMode
        return view
    }

    func updateNSView(_ nsView: AppAppearanceApplyingView, context: Context) {
        nsView.appearanceMode = appearanceMode
        nsView.applyAppearance()
    }
}

private final class AppAppearanceApplyingView: NSView {
    var appearanceMode: AppAppearanceMode = .system

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyAppearance()
    }

    func applyAppearance() {
        let appearance = appearanceMode.nsAppearance
        NSApp.appearance = appearance
        window?.appearance = appearance
    }
}
