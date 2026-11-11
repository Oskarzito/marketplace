import Foundation

nonisolated protocol FavoritesStore: Sendable {
    func loadAll() async -> [Favorite]
    func add(_ ad: Ad, imageData: Data?) async throws
    func remove(id: Ad.ID) async throws
}

actor FileFavoritesStore: FavoritesStore {
    private let fileURL = URL.applicationSupportDirectory.appending(path: "favorites.json")

    func loadAll() -> [Favorite] {
        read()
    }

    func add(_ ad: Ad, imageData: Data?) throws {
        var favorites = read().filter { $0.ad.id != ad.id }
        favorites.insert(Favorite(ad: ad, imageData: imageData), at: 0)
        try write(favorites)
    }

    func remove(id: Ad.ID) throws {
        try write(read().filter { $0.ad.id != id })
    }

    private func read() -> [Favorite] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Favorite].self, from: data)) ?? []
    }

    private func write(_ favorites: [Favorite]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(favorites).write(to: fileURL, options: .atomic)
    }
}
