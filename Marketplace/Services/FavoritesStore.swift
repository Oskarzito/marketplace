import Foundation

nonisolated protocol FavoritesStore: Sendable {
    /// Newest favorite first.
    func loadAll() async -> [Favorite]
    /// Saving an ad that is already a favorite replaces the old record.
    func add(_ ad: Ad, imageData: Data?) async throws
    func remove(id: Ad.ID) async throws
}

/// Keeps all favorites in one JSON file. Favorites are few and read once at launch,
/// so a file is enough; there are no queries that would call for a database.
actor FileFavoritesStore: FavoritesStore {
    // Application Support, not Caches: the system may purge Caches, which would silently break offline use.
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
        // No file yet, or one that can't be decoded, means "no favorites". Launch must never fail on this.
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Favorite].self, from: data)) ?? []
    }

    private func write(_ favorites: [Favorite]) throws {
        // Application Support does not exist on a fresh install.
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        // Atomic: a crash mid-write leaves the previous file intact instead of a half-written one.
        try JSONEncoder().encode(favorites).write(to: fileURL, options: .atomic)
    }
}
