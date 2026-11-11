import UIKit

actor ImageLoader {
    // One cache for the whole app. The SwiftUI environment default points here, because an
    // `@Entry` default built inline would create a fresh, empty cache on every read.
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        let image = try await image(from: data(for: url))
        cache.setObject(image, forKey: url as NSURL)
        return image
    }

    /// For bytes that are already on the device, such as a saved favorite.
    func image(from data: Data) async throws -> UIImage {
        // UIKit normally decodes an image lazily on first draw, which means on the main
        // thread in the middle of scrolling. Decoding here keeps that work off the main thread.
        guard let image = await UIImage(data: data)?.byPreparingForDisplay() else {
            throw URLError(.cannotDecodeContentData)
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
