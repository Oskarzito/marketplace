import Foundation

nonisolated protocol AdsService: Sendable {
    func fetchAds() async throws -> [Ad]
}

nonisolated struct URLSessionAdsService: AdsService {
    private static let feedURL = URL(
        string: "https://gist.githubusercontent.com/baldermork/6a1bcc8f429dcdb8f9196e917e5138bd/raw/discover.json"
    )!

    func fetchAds() async throws -> [Ad] {
        let (data, response) = try await URLSession.shared.data(from: Self.feedURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try await Self.decodeAds(from: data)
    }

    // The feed may grow much larger than today's 20 ads. `@concurrent` keeps decoding off the
    // main actor, where this service is called from under the project's default isolation.
    @concurrent
    private static func decodeAds(from data: Data) async throws -> [Ad] {
        let decoder = JSONDecoder()
        // The nested `content` object uses snake_case keys.
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(AdsResponse.self, from: data).items.map(Ad.init(response:))
    }
}
