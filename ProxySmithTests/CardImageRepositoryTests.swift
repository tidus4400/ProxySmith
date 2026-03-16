import Foundation
import Testing
@testable import ProxySmith

@Suite(.serialized)
struct CardImageRepositoryTests {
    @Test
    func cachePathUsesHostAndImageDirectories() async throws {
        let rootDirectory = temporaryRootDirectory()
        let repository = CardImageRepository(
            cacheDirectory: rootDirectory.appendingPathComponent("cache", isDirectory: true),
            session: makeSession()
        )
        let url = URL(string: "https://cards.scryfall.io/png/front/3/c/3cee9303-9d65-45a2-93d4-ef4aba59141b.png?1730489152")!

        let cacheFileURL = await repository.cacheFileURL(for: url)

        #expect(cacheFileURL.path.contains("/cards.scryfall.io/png/front/3/c/"))

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    @Test
    func dataUsesCachedImageUntilCachePeriodExpires() async throws {
        let rootDirectory = temporaryRootDirectory()
        let cacheDirectory = rootDirectory.appendingPathComponent("cache", isDirectory: true)
        let repository = CardImageRepository(
            cacheDirectory: cacheDirectory,
            session: makeSession()
        )
        let url = URL(string: "https://cards.scryfall.io/large/front/1/2/12345678-1234-1234-1234-123456789abc.jpg")!

        MockURLProtocol.reset()
        MockURLProtocol.configure(data: Data("first-image".utf8))

        let firstLoad = try await repository.data(for: url, maxAge: 7 * 24 * 60 * 60)
        #expect(firstLoad == Data("first-image".utf8))
        #expect(MockURLProtocol.requestCount == 1)

        MockURLProtocol.configure(data: Data("second-image".utf8))

        let cachedLoad = try await repository.data(for: url, maxAge: 7 * 24 * 60 * 60)
        #expect(cachedLoad == Data("first-image".utf8))
        #expect(MockURLProtocol.requestCount == 1)

        let cacheFileURL = await repository.cacheFileURL(for: url)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSinceNow: -(8 * 24 * 60 * 60))],
            ofItemAtPath: cacheFileURL.path
        )

        let refreshedRepository = CardImageRepository(
            cacheDirectory: cacheDirectory,
            session: makeSession()
        )
        let refreshedLoad = try await refreshedRepository.data(for: url, maxAge: 7 * 24 * 60 * 60)
        #expect(refreshedLoad == Data("second-image".utf8))
        #expect(MockURLProtocol.requestCount == 2)

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    @Test
    func staleCacheIsReturnedWhenRefreshFails() async throws {
        let rootDirectory = temporaryRootDirectory()
        let cacheDirectory = rootDirectory.appendingPathComponent("cache", isDirectory: true)
        let repository = CardImageRepository(
            cacheDirectory: cacheDirectory,
            session: makeSession()
        )
        let url = URL(string: "https://cards.scryfall.io/normal/front/a/b/abcdefab-cdef-abcd-efab-cdefabcdefab.jpg")!

        MockURLProtocol.reset()
        MockURLProtocol.configure(data: Data("cached-image".utf8))

        let cachedImage = try await repository.data(for: url, maxAge: 24 * 60 * 60)
        #expect(cachedImage == Data("cached-image".utf8))
        #expect(MockURLProtocol.requestCount == 1)

        let cacheFileURL = await repository.cacheFileURL(for: url)
        let staleDate = Date(timeIntervalSinceNow: -(3 * 24 * 60 * 60))
        try FileManager.default.setAttributes(
            [.modificationDate: staleDate],
            ofItemAtPath: cacheFileURL.path
        )

        MockURLProtocol.configure(data: Data(), statusCode: 500)

        let refreshedRepository = CardImageRepository(
            cacheDirectory: cacheDirectory,
            session: makeSession()
        )
        let staleFallback = try await refreshedRepository.data(for: url, maxAge: 24 * 60 * 60)
        #expect(staleFallback == Data("cached-image".utf8))
        #expect(MockURLProtocol.requestCount == 2)

        let refreshedAttributes = try cacheFileURL.resourceValues(forKeys: [.contentModificationDateKey])
        #expect(refreshedAttributes.contentModificationDate == staleDate)

        try? FileManager.default.removeItem(at: rootDirectory)
    }

    @Test
    func memoryStorageCachesWithoutWritingFiles() async throws {
        let repository = CardImageRepository(
            storage: .memory,
            session: makeSession()
        )
        let url = URL(string: "https://cards.scryfall.io/small/front/9/9/99999999-9999-9999-9999-999999999999.jpg")!

        MockURLProtocol.reset()
        MockURLProtocol.configure(data: Data("memory-image".utf8))

        let firstLoad = try await repository.data(for: url, maxAge: 7 * 24 * 60 * 60)
        let secondLoad = try await repository.data(for: url, maxAge: 7 * 24 * 60 * 60)
        let virtualCacheFileURL = await repository.cacheFileURL(for: url)

        #expect(firstLoad == Data("memory-image".utf8))
        #expect(secondLoad == Data("memory-image".utf8))
        #expect(MockURLProtocol.requestCount == 1)
        #expect(FileManager.default.fileExists(atPath: virtualCacheFileURL.path) == false)
    }

    private func temporaryRootDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("ProxySmith-CardImageRepositoryTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    private struct State {
        var data = Data()
        var statusCode = 200
        var requestCount = 0
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var state = State()

    static var requestCount: Int {
        lock.withLock { state.requestCount }
    }

    static func configure(data: Data, statusCode: Int = 200) {
        lock.withLock {
            state.data = data
            state.statusCode = statusCode
        }
    }

    static func reset() {
        lock.withLock {
            state = State()
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let snapshot = Self.lock.withLock { () -> State in
            Self.state.requestCount += 1
            return Self.state
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: snapshot.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if snapshot.data.isEmpty == false {
            client?.urlProtocol(self, didLoad: snapshot.data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
