import CryptoKit
import Foundation

private final class MemoryCachedImage: NSObject {
    let data: NSData
    let storedAt: Date

    init(data: Data, storedAt: Date) {
        self.data = data as NSData
        self.storedAt = storedAt
    }
}

actor CardImageRepository {
    enum Storage: Sendable {
        case disk(URL)
        case memory

        var cacheDirectory: URL {
            switch self {
            case let .disk(directory):
                directory
            case .memory:
                URL(fileURLWithPath: "/virtual/proxysmith/cache/card-images", isDirectory: true)
            }
        }
    }

    private struct DiskCachedImage {
        let data: Data
        let storedAt: Date
    }

    private struct FetchResult {
        let data: Data
        let storedAt: Date
        let shouldPersist: Bool
    }

    private let storage: Storage
    private let session: URLSession
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let dateProvider: @Sendable () -> Date
    private let memoryCache = NSCache<NSURL, MemoryCachedImage>()
    private var inFlight: [URL: Task<FetchResult, Error>] = [:]
    private var inMemoryStoredImages: [URL: DiskCachedImage] = [:]

    init(
        storage: Storage = LaunchConfiguration.makeImageCacheStorage(),
        session: URLSession? = nil,
        fileManager: FileManager = .default,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.storage = storage
        self.fileManager = fileManager
        self.cacheDirectory = storage.cacheDirectory
        self.dateProvider = dateProvider

        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpAdditionalHeaders = [
                "User-Agent": "ProxySmith/0.1 (macOS 26; cached image fetcher)"
            ]
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 60
            self.session = URLSession(configuration: configuration)
        }

        memoryCache.countLimit = 256
    }

    init(
        cacheDirectory: URL,
        session: URLSession? = nil,
        fileManager: FileManager = .default,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.init(
            storage: .disk(cacheDirectory),
            session: session,
            fileManager: fileManager,
            dateProvider: dateProvider
        )
    }

    func data(for url: URL, maxAge: TimeInterval) async throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        let now = dateProvider()

        if let cached = memoryCache.object(forKey: url as NSURL),
           now.timeIntervalSince(cached.storedAt) <= maxAge {
            return cached.data as Data
        }

        let diskCachedImage = try loadCachedImage(for: url)
        if let diskCachedImage,
           now.timeIntervalSince(diskCachedImage.storedAt) <= maxAge {
            memoryCache.setObject(
                MemoryCachedImage(data: diskCachedImage.data, storedAt: diskCachedImage.storedAt),
                forKey: url as NSURL
            )
            return diskCachedImage.data
        }

        if let task = inFlight[url] {
            let result = try await task.value
            memoryCache.setObject(
                MemoryCachedImage(data: result.data, storedAt: result.storedAt),
                forKey: url as NSURL
            )
            return result.data
        }

        let staleCachedImage = diskCachedImage
        let session = self.session
        let task = Task<FetchResult, Error> {
            do {
                let (data, response) = try await session.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200 ..< 300).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                return FetchResult(
                    data: data,
                    storedAt: now,
                    shouldPersist: true
                )
            } catch {
                if let staleCachedImage {
                    return FetchResult(
                        data: staleCachedImage.data,
                        storedAt: staleCachedImage.storedAt,
                        shouldPersist: false
                    )
                }

                throw error
            }
        }

        inFlight[url] = task

        do {
            let result = try await task.value
            if result.shouldPersist {
                try store(result.data, for: url, storedAt: result.storedAt)
            }
            memoryCache.setObject(
                MemoryCachedImage(data: result.data, storedAt: result.storedAt),
                forKey: url as NSURL
            )
            inFlight[url] = nil
            return result.data
        } catch {
            inFlight[url] = nil
            throw error
        }
    }

    func prefetchData(for urls: [URL], maxAge: TimeInterval) async throws -> [URL: Data] {
        var result: [URL: Data] = [:]

        for url in urls {
            result[url] = try await data(for: url, maxAge: maxAge)
        }

        return result
    }

    func cacheFileURL(for url: URL) -> URL {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = sanitizePathComponent(components?.host ?? "unknown-host")
        let pathComponents = url.pathComponents
            .filter { $0 != "/" }
            .map(sanitizePathComponent)

        let directories = Array(pathComponents.dropLast())
        let originalFilename = pathComponents.last ?? "image"
        let baseFilename = URL(fileURLWithPath: originalFilename)
            .deletingPathExtension()
            .lastPathComponent
        let pathExtension = URL(fileURLWithPath: originalFilename).pathExtension
        let hashPrefix = cacheKey(for: url).prefix(12)

        let filename: String
        if pathExtension.isEmpty {
            filename = "\(baseFilename)--\(hashPrefix)"
        } else {
            filename = "\(baseFilename)--\(hashPrefix).\(pathExtension)"
        }

        return directories.reduce(
            cacheDirectory.appendingPathComponent(host, isDirectory: true)
        ) { partialResult, component in
            partialResult.appendingPathComponent(component, isDirectory: true)
        }
        .appendingPathComponent(filename, isDirectory: false)
    }

    private func loadCachedImage(for url: URL) throws -> DiskCachedImage? {
        switch storage {
        case .memory:
            return inMemoryStoredImages[url]
        case .disk:
            let fileURL = cacheFileURL(for: url)
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return nil
            }

            let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
            let storedAt = resourceValues.contentModificationDate ?? .distantPast
            let data = try Data(contentsOf: fileURL)
            return DiskCachedImage(data: data, storedAt: storedAt)
        }
    }

    private func store(_ data: Data, for url: URL, storedAt: Date) throws {
        switch storage {
        case .memory:
            inMemoryStoredImages[url] = DiskCachedImage(data: data, storedAt: storedAt)
        case .disk:
            let fileURL = cacheFileURL(for: url)

            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            try data.write(to: fileURL, options: .atomic)
            try fileManager.setAttributes(
                [.modificationDate: storedAt],
                ofItemAtPath: fileURL.path
            )
        }
    }

    private func cacheKey(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func sanitizePathComponent(_ value: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: "._-")
        )

        let sanitizedScalars = value.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : "_"
        }

        let sanitized = String(sanitizedScalars)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))

        return sanitized.isEmpty ? "item" : sanitized
    }
}
