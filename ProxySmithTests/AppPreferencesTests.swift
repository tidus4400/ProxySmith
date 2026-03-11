import Foundation
import Testing
@testable import ProxySmith

struct AppPreferencesTests {
    @Test
    @MainActor
    func preferencesPersistToggleAndCounter() {
        let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let preferences = AppPreferences(defaults: defaults)
        preferences.globalDeckNumberingEnabled = false
        preferences.nextGlobalDeckNumber = 12

        let reloaded = AppPreferences(defaults: defaults)

        #expect(reloaded.globalDeckNumberingEnabled == false)
        #expect(reloaded.nextGlobalDeckNumber == 12)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test
    @MainActor
    func resetCounterReturnsToOne() {
        let suiteName = "AppPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let preferences = AppPreferences(defaults: defaults)
        preferences.nextGlobalDeckNumber = 9
        preferences.resetDeckNumberCounter()

        #expect(preferences.nextGlobalDeckNumber == 1)

        defaults.removePersistentDomain(forName: suiteName)
    }
}

