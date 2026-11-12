import UIKit

actor ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL?, storedData: Data?) async throws -> UIImage {
        if let url, let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        let data: Data
        if let storedData {
            data = storedData
        } else if let url {
            data = try await self.data(for: url)
        } else {
            throw URLError(.badURL)
        }

        guard let image = await UIImage(data: data)?.byPreparingForDisplay() else {
            throw URLError(.cannotDecodeContentData)
        }
        if let url {
            cache.setObject(image, forKey: url as NSURL)
        }
        return image
    }

    func data(for url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
