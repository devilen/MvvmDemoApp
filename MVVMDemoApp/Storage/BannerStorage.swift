import Foundation

protocol BannerStorageType {
    func save(banners: [Banner]) throws
    func fetchBanners() -> [Banner]
    func fetchStaleBanners() -> [Banner]
}

final class BannerStorage: BannerStorageType {
    private let cacheStore: FileCacheStore
    private let filename = "banner-list-cache.json"
    private let ttl: TimeInterval

    init(cacheStore: FileCacheStore, ttl: TimeInterval = 1800) {
        self.cacheStore = cacheStore
        self.ttl = ttl
    }

    func save(banners: [Banner]) throws {
        let entry = CachedEntry(data: banners, cachedAt: Date())
        try cacheStore.save(entry, filename: filename)
    }

    func fetchBanners() -> [Banner] {
        guard let entry = cacheStore.load(CachedEntry<[Banner]>.self, filename: filename),
              !entry.isExpired(ttl: ttl) else {
            return []
        }
        return entry.data
    }

    func fetchStaleBanners() -> [Banner] {
        guard let entry = cacheStore.load(CachedEntry<[Banner]>.self, filename: filename) else {
            return []
        }
        return entry.data
    }
}
