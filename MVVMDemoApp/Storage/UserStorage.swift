import Foundation

protocol UserStorageType {
    func save(user: User) throws
    func fetchUser() -> User?
    func fetchStaleUser() -> User?
}

final class UserStorage: UserStorageType {
    private let cacheStore: FileCacheStore
    private let filename = "user-profile-cache.json"
    private let ttl: TimeInterval

    init(cacheStore: FileCacheStore, ttl: TimeInterval = 1800) {
        self.cacheStore = cacheStore
        self.ttl = ttl
    }

    func save(user: User) throws {
        let entry = CachedEntry(data: user, cachedAt: Date())
        try cacheStore.save(entry, filename: filename)
    }

    func fetchUser() -> User? {
        guard let entry = cacheStore.load(CachedEntry<User>.self, filename: filename),
              !entry.isExpired(ttl: ttl) else {
            return nil
        }
        return entry.data
    }

    func fetchStaleUser() -> User? {
        guard let entry = cacheStore.load(CachedEntry<User>.self, filename: filename) else {
            return nil
        }
        return entry.data
    }
}
