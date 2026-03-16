import Foundation
import Observation

private struct AppPreferencesSnapshot: Codable {
    var globalDeckNumberingEnabled = true
    var nextGlobalDeckNumber = 1
    var cardImageCachePeriodDays = AppPreferences.defaultCardImageCachePeriodDays
}

@MainActor
@Observable
final class AppPreferences {
    nonisolated static let defaultCardImageCachePeriodDays = 7

    private let fileManager: FileManager
    private let storageLayout: ProxySmithStorageLayout
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var globalDeckNumberingEnabled: Bool {
        didSet {
            persist()
        }
    }

    var nextGlobalDeckNumber: Int {
        didSet {
            let sanitizedValue = max(nextGlobalDeckNumber, 1)
            guard sanitizedValue == nextGlobalDeckNumber else {
                nextGlobalDeckNumber = sanitizedValue
                return
            }

            persist()
        }
    }

    var cardImageCachePeriodDays: Int {
        didSet {
            let sanitizedValue = min(max(cardImageCachePeriodDays, 1), 365)
            guard sanitizedValue == cardImageCachePeriodDays else {
                cardImageCachePeriodDays = sanitizedValue
                return
            }

            persist()
        }
    }

    var cardImageCacheLifetime: TimeInterval {
        TimeInterval(cardImageCachePeriodDays * 24 * 60 * 60)
    }

    var settingsFileLocationDescription: String {
        storageLayout.settingsFile.pathRelativeToHome(fileManager: fileManager)
    }

    var cardImageCacheLocationDescription: String {
        storageLayout.cardImageCacheDirectory.pathRelativeToHome(fileManager: fileManager)
    }

    init(
        storageLayout: ProxySmithStorageLayout = LaunchConfiguration.makeStorageLayout(),
        fileManager: FileManager = .default
    ) {
        self.storageLayout = storageLayout
        self.fileManager = fileManager

        let snapshot = Self.loadSnapshot(
            from: storageLayout.settingsFile,
            fileManager: fileManager,
            decoder: decoder
        )

        globalDeckNumberingEnabled = snapshot.globalDeckNumberingEnabled
        nextGlobalDeckNumber = max(snapshot.nextGlobalDeckNumber, 1)
        cardImageCachePeriodDays = min(max(snapshot.cardImageCachePeriodDays, 1), 365)

        persist()
    }

    func resetDeckNumberCounter() {
        nextGlobalDeckNumber = 1
    }

    private func persist() {
        let snapshot = AppPreferencesSnapshot(
            globalDeckNumberingEnabled: globalDeckNumberingEnabled,
            nextGlobalDeckNumber: nextGlobalDeckNumber,
            cardImageCachePeriodDays: cardImageCachePeriodDays
        )

        do {
            try fileManager.createDirectory(
                at: storageLayout.settingsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let data = try encoder.encode(snapshot)
            try data.write(to: storageLayout.settingsFile, options: .atomic)
        } catch {
            assertionFailure("Failed to persist app preferences: \(error.localizedDescription)")
        }
    }

    private static func loadSnapshot(
        from url: URL,
        fileManager: FileManager,
        decoder: JSONDecoder
    ) -> AppPreferencesSnapshot {
        guard fileManager.fileExists(atPath: url.path) else {
            return AppPreferencesSnapshot()
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(AppPreferencesSnapshot.self, from: data)
        } catch {
            return AppPreferencesSnapshot()
        }
    }
}
