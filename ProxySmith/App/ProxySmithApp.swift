import SwiftData
import SwiftUI

@main
struct ProxySmithApp: App {
    private let modelContainer: ModelContainer
    private let appPreferences: AppPreferences
    private let services = AppServices.live

    init() {
        do {
            let userDefaults = LaunchConfiguration.makeUserDefaults()
            appPreferences = AppPreferences(defaults: userDefaults)
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
            ContentView()
                .environment(\.appServices, services)
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
            SettingsView()
                .environment(appPreferences)
        }
        .modelContainer(modelContainer)
    }
}
