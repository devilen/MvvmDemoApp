import Foundation

protocol UserStorageType {
    func save(user: User) throws
    func fetchUser() -> User?
    func fetchStaleUser() -> User?
}

final class UserStorage: UserStorageType {
    private let store: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder: JSONDecoder
    private let key = "stored.user.profile"
    private let ttl: TimeInterval

    init(store: UserDefaults, ttl: TimeInterval = 1800) {
        self.store = store
        self.ttl = ttl
        self.decoder = JSONDecoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func save(user: User) throws {
        do {
            let entry = CachedEntry(data: user, cachedAt: Date())
            let data = try encoder.encode(entry)
            store.set(data, forKey: key)
        } catch {
            throw AppError.storage(error.localizedDescription)
        }
    }

    func fetchUser() -> User? {
        guard let data = store.data(forKey: key),
              let entry = try? decoder.decode(CachedEntry<User>.self, from: data),
              !entry.isExpired(ttl: ttl) else {
            return nil
        }
        return entry.data
    }

    func fetchStaleUser() -> User? {
        guard let data = store.data(forKey: key),
              let entry = try? decoder.decode(CachedEntry<User>.self, from: data) else {
            return nil
        }
        return entry.data
    }
}
