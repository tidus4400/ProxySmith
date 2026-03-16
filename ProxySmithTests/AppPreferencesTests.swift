import Foundation
import Testing
@testable import ProxySmith

struct AppPreferencesTests {
    @Test
    @MainActor
    func preferencesPersistDeckNumberingAndCachePeriod() throws {
        let rootDirectory = temporaryRootDirectory()
        let storageLayout = ProxySmithStorageLayout(rootDirectory: rootDirectory)

        let preferences = AppPreferences(storageLayout: storageLayout)
        preferences.globalDeckNumberingEnabled = false
        preferences.nextGlobalDeckNumber = 12
        preferences.cardImageCachePeriodDays = 14

        let reloaded = AppPreferences(storageLayout: storageLayout)

        #expect(reloaded.globalDeckNumberingEnabled == false)
        #expect(reloaded.nextGlobalDeckNumber == 12)
        #expect(reloaded.cardImageCachePeriodDays == 14)

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    @Test
    @MainActor
    func resetCounterReturnsToOne() throws {
        let rootDirectory = temporaryRootDirectory()
        let storageLayout = ProxySmithStorageLayout(rootDirectory: rootDirectory)

        let preferences = AppPreferences(storageLayout: storageLayout)
        preferences.nextGlobalDeckNumber = 9
        preferences.resetDeckNumberCounter()

        #expect(preferences.nextGlobalDeckNumber == 1)

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    @Test
    @MainActor
    func cachePeriodIsClampedToValidRange() throws {
        let rootDirectory = temporaryRootDirectory()
        let storageLayout = ProxySmithStorageLayout(rootDirectory: rootDirectory)

        let preferences = AppPreferences(storageLayout: storageLayout)
        preferences.cardImageCachePeriodDays = 0
        #expect(preferences.cardImageCachePeriodDays == 1)

        preferences.cardImageCachePeriodDays = 999
        #expect(preferences.cardImageCachePeriodDays == 365)

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    private func temporaryRootDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("ProxySmith-AppPreferencesTests-\(UUID().uuidString)", isDirectory: true)
    }
}
