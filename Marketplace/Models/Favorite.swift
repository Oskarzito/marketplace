import Foundation

nonisolated struct Favorite: Codable, Sendable {
    let ad: Ad
    let imageData: Data?
}
