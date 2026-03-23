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
        try preferences.saveCardImageCacheDirectory(from: "~/Library/Caches/ProxySmith/CardImages")

        let reloaded = AppPreferences(storageLayout: storageLayout)

        #expect(reloaded.globalDeckNumberingEnabled == false)
        #expect(reloaded.nextGlobalDeckNumber == 12)
        #expect(reloaded.cardImageCachePeriodDays == 14)
        #expect(
            reloaded.cardImageCacheDirectory.path ==
                FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Caches/ProxySmith/CardImages", isDirectory: true)
                .path
        )

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    @Test
    @MainActor
    func appearanceModePersistsAcrossReload() throws {
        let rootDirectory = temporaryRootDirectory()
        let storageLayout = ProxySmithStorageLayout(rootDirectory: rootDirectory)

        let preferences = AppPreferences(storageLayout: storageLayout)
        preferences.appearanceMode = .dark

        let reloaded = AppPreferences(storageLayout: storageLayout)

        #expect(reloaded.appearanceMode == .dark)

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    @Test
    @MainActor
    func legacySettingsWithoutAppearanceModeKeepExistingValues() throws {
        let rootDirectory = temporaryRootDirectory()
        let storageLayout = ProxySmithStorageLayout(rootDirectory: rootDirectory)

        try FileManager.default.createDirectory(
            at: storageLayout.settingsDirectory,
            withIntermediateDirectories: true
        )

        let legacyPayload = """
        {
          "globalDeckNumberingEnabled": false,
          "nextGlobalDeckNumber": 12,
          "cardImageCachePeriodDays": 14
        }
        """
        try legacyPayload.write(
            to: storageLayout.settingsFile,
            atomically: true,
            encoding: .utf8
        )

        let reloaded = AppPreferences(storageLayout: storageLayout)

        #expect(reloaded.globalDeckNumberingEnabled == false)
        #expect(reloaded.nextGlobalDeckNumber == 12)
        #expect(reloaded.cardImageCachePeriodDays == 14)
        #expect(reloaded.appearanceMode == .system)

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

    @Test
    @MainActor
    func blankCacheFolderInputRestoresDefaultLocation() throws {
        let rootDirectory = temporaryRootDirectory()
        let storageLayout = ProxySmithStorageLayout(rootDirectory: rootDirectory)

        let preferences = AppPreferences(storageLayout: storageLayout)
        try preferences.saveCardImageCacheDirectory(from: "/tmp/proxysmith-card-images")
        try preferences.saveCardImageCacheDirectory(from: "")

        let reloaded = AppPreferences(storageLayout: storageLayout)

        #expect(reloaded.cardImageCacheDirectory.path == storageLayout.cardImageCacheDirectory.path)

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    @Test
    @MainActor
    func cacheFolderRejectsRelativePaths() throws {
        let rootDirectory = temporaryRootDirectory()
        let storageLayout = ProxySmithStorageLayout(rootDirectory: rootDirectory)

        let preferences = AppPreferences(storageLayout: storageLayout)

        #expect(throws: AppPreferences.CardImageCacheDirectoryError.invalidPathFormat) {
            try preferences.previewCardImageCacheDirectory(for: "relative/cache-folder")
        }

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    private func temporaryRootDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("ProxySmith-AppPreferencesTests-\(UUID().uuidString)", isDirectory: true)
    }
}
