import SwiftData
import SwiftUI

@main
struct ProxySmithApp: App {
    private let modelContainer: ModelContainer
    private let services = AppServices.live

    init() {
        do {
            modelContainer = try ModelContainer(for: Deck.self, DeckCard.self)
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appServices, services)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 1480, height: 920)
        .commands {
            SidebarCommands()
        }
    }
}

