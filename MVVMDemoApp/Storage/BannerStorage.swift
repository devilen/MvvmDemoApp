import Foundation

protocol BannerStorageType {
    func save(banners: [Banner]) throws
    func fetchBanners() -> [Banner]
    func fetchStaleBanners() -> [Banner]
}

final class BannerStorage: BannerStorageType {
    private let store: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let key = "stored.banner.list"
    private let ttl: TimeInterval

    init(store: UserDefaults, ttl: TimeInterval = 1800) {
        self.store = store
        self.ttl = ttl
    }

    func save(banners: [Banner]) throws {
        do {
            let entry = CachedEntry(data: banners, cachedAt: Date())
            let data = try encoder.encode(entry)
            store.set(data, forKey: key)
        } catch {
            throw AppError.storage(error.localizedDescription)
        }
    }

    func fetchBanners() -> [Banner] {
        guard let data = store.data(forKey: key),
              let entry = try? decoder.decode(CachedEntry<[Banner]>.self, from: data),
              !entry.isExpired(ttl: ttl) else {
            return []
        }
        return entry.data
    }

    func fetchStaleBanners() -> [Banner] {
        guard let data = store.data(forKey: key),
              let entry = try? decoder.decode(CachedEntry<[Banner]>.self, from: data) else {
            return []
        }
        return entry.data
    }
}
