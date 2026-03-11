import Foundation

actor RequestThrottler {
    private let minimumSpacing: Duration
    private let clock = ContinuousClock()
    private var lastRequest: ContinuousClock.Instant?

    init(minimumSpacing: Duration) {
        self.minimumSpacing = minimumSpacing
    }

    func awaitTurn() async throws {
        if let lastRequest {
            let nextAllowedRequest = lastRequest.advanced(by: minimumSpacing)
            let now = clock.now

            if now < nextAllowedRequest {
                try await Task.sleep(for: now.duration(to: nextAllowedRequest))
            }
        }

        lastRequest = clock.now
    }
}

actor ScryfallClient {
    private let decoder: JSONDecoder
    private let session: URLSession
    private let throttler = RequestThrottler(minimumSpacing: .milliseconds(150))

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(memoryCapacity: 64 * 1_024 * 1_024, diskCapacity: 256 * 1_024 * 1_024)
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "User-Agent": "ProxySmith/0.1 (macOS 26; SwiftUI native client)"
        ]

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        session = URLSession(configuration: configuration)
    }

    func searchCards(query: String) async throws -> [ScryfallCard] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        do {
            let response: ScryfallSearchResponse = try await request(
                path: "/cards/search",
                queryItems: [
                    URLQueryItem(name: "q", value: trimmed),
                    URLQueryItem(name: "unique", value: "cards"),
                    URLQueryItem(name: "order", value: "name")
                ]
            )
            return Array(response.data.prefix(24))
        } catch let error as ScryfallAPIError where error.status == 404 {
            return []
        }
    }

    private func request<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        try await throttler.awaitTurn()

        var components = URLComponents(string: "https://api.scryfall.com\(path)")!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            if let apiError = try? decoder.decode(ScryfallAPIError.self, from: data) {
                throw apiError
            }

            throw URLError(.badServerResponse)
        }

        return try decoder.decode(T.self, from: data)
    }
}

