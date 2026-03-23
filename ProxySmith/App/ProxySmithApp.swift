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
            .preferredColorScheme(appPreferences.preferredColorScheme)
    }
}
