import UIKit

actor ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()

    // `storedData` is the image saved with a favorite. If it's there we use it instead of the network,
    // which is what makes favorites work offline.
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
        // UIKit normally decodes an image lazily on first draw, which can mean on the main
        // thread in the middle of scrolling. Decoding here keeps that work off the main thread.
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
