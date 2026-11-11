import Foundation

/// One saved favorite: a snapshot of the ad plus its image bytes, so it can be shown fully offline.
nonisolated struct Favorite: Codable, Sendable {
    let ad: Ad
    let imageData: Data?
}
