import Foundation

actor CardImageRepository {
    private let session: URLSession
    private let cache = NSCache<NSURL, NSData>()
    private var inFlight: [URL: Task<Data, Error>] = [:]

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(memoryCapacity: 128 * 1_024 * 1_024, diskCapacity: 512 * 1_024 * 1_024)
        configuration.httpAdditionalHeaders = [
            "User-Agent": "ProxySmith/0.1 (macOS 26; print image fetcher)"
        ]
        session = URLSession(configuration: configuration)
        cache.countLimit = 256
    }

    func data(for url: URL) async throws -> Data {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached as Data
        }

        if let task = inFlight[url] {
            return try await task.value
        }

        let task = Task<Data, Error> {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return data
        }

        inFlight[url] = task

        do {
            let data = try await task.value
            cache.setObject(data as NSData, forKey: url as NSURL)
            inFlight[url] = nil
            return data
        } catch {
            inFlight[url] = nil
            throw error
        }
    }

    func prefetchData(for urls: [URL]) async throws -> [URL: Data] {
        var result: [URL: Data] = [:]

        for url in urls {
            result[url] = try await data(for: url)
        }

        return result
    }
}

