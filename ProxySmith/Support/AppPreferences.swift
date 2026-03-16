import Foundation
import Observation

private struct AppPreferencesSnapshot: Codable {
    var globalDeckNumberingEnabled = true
    var nextGlobalDeckNumber = 1
    var cardImageCachePeriodDays = AppPreferences.defaultCardImageCachePeriodDays
    var cardImageCacheDirectoryPath: String?
}

@MainActor
@Observable
final class AppPreferences {
    nonisolated static let defaultCardImageCachePeriodDays = 7

    enum CardImageCacheDirectoryError: LocalizedError, Equatable {
        case invalidPathFormat

        var errorDescription: String? {
            switch self {
            case .invalidPathFormat:
                "Use an absolute path or a path that starts with `~/`."
            }
        }
    }

    private let fileManager: FileManager
    private let storageLayout: ProxySmithStorageLayout
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cardImageCacheDirectoryOverridePath: String?

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

    var cardImageCacheDirectory: URL {
        Self.resolveCardImageCacheDirectory(
            overridePath: cardImageCacheDirectoryOverridePath,
            defaultDirectory: storageLayout.cardImageCacheDirectory
        )
    }

    var cardImageCacheLocationDescription: String {
        cardImageCacheDirectory.pathRelativeToHome(fileManager: fileManager)
    }

    var cardImageCacheDirectoryInput: String {
        cardImageCacheLocationDescription
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
        cardImageCacheDirectoryOverridePath = Self.normalizeStoredCardImageCacheDirectoryOverridePath(
            snapshot.cardImageCacheDirectoryPath,
            defaultDirectory: storageLayout.cardImageCacheDirectory
        )

        persist()
    }

    func resetDeckNumberCounter() {
        nextGlobalDeckNumber = 1
    }

    func previewCardImageCacheDirectory(for input: String) throws -> URL {
        let normalizedOverridePath = try Self.normalizeCardImageCacheDirectoryOverridePath(
            from: input,
            fileManager: fileManager,
            defaultDirectory: storageLayout.cardImageCacheDirectory
        )
        return Self.resolveCardImageCacheDirectory(
            overridePath: normalizedOverridePath,
            defaultDirectory: storageLayout.cardImageCacheDirectory
        )
    }

    @discardableResult
    func saveCardImageCacheDirectory(from input: String) throws -> URL {
        let normalizedOverridePath = try Self.normalizeCardImageCacheDirectoryOverridePath(
            from: input,
            fileManager: fileManager,
            defaultDirectory: storageLayout.cardImageCacheDirectory
        )
        cardImageCacheDirectoryOverridePath = normalizedOverridePath
        persist()
        return cardImageCacheDirectory
    }

    private func persist() {
        let snapshot = AppPreferencesSnapshot(
            globalDeckNumberingEnabled: globalDeckNumberingEnabled,
            nextGlobalDeckNumber: nextGlobalDeckNumber,
            cardImageCachePeriodDays: cardImageCachePeriodDays,
            cardImageCacheDirectoryPath: cardImageCacheDirectoryOverridePath
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

    private static func normalizeStoredCardImageCacheDirectoryOverridePath(
        _ storedPath: String?,
        defaultDirectory: URL
    ) -> String? {
        guard let storedPath,
              storedPath.isEmpty == false,
              storedPath.hasPrefix("/") else {
            return nil
        }

        let normalizedPath = URL(fileURLWithPath: storedPath, isDirectory: true)
            .standardizedFileURL
            .path
        return normalizedPath == defaultDirectory.standardizedFileURL.path ? nil : normalizedPath
    }

    private static func normalizeCardImageCacheDirectoryOverridePath(
        from input: String,
        fileManager: FileManager,
        defaultDirectory: URL
    ) throws -> String? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedInput.isEmpty == false else {
            return nil
        }

        let expandedPath: String
        if trimmedInput == "~" {
            expandedPath = fileManager.homeDirectoryForCurrentUser.path
        } else if trimmedInput.hasPrefix("~/") {
            expandedPath = fileManager.homeDirectoryForCurrentUser.path
                .appending("/\(trimmedInput.dropFirst(2))")
        } else if trimmedInput.hasPrefix("/") {
            expandedPath = trimmedInput
        } else {
            throw CardImageCacheDirectoryError.invalidPathFormat
        }

        let normalizedPath = URL(fileURLWithPath: expandedPath, isDirectory: true)
            .standardizedFileURL
            .path
        return normalizedPath == defaultDirectory.standardizedFileURL.path ? nil : normalizedPath
    }

    private static func resolveCardImageCacheDirectory(
        overridePath: String?,
        defaultDirectory: URL
    ) -> URL {
        guard let overridePath else {
            return defaultDirectory
        }

        return URL(fileURLWithPath: overridePath, isDirectory: true)
            .standardizedFileURL
    }
}
