import Foundation

struct CachedEntry<T: Codable>: Codable {
    let data: T
    let cachedAt: Date

    func isExpired(ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(cachedAt) > ttl
    }
}
