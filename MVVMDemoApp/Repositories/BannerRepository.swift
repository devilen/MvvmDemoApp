import Foundation

protocol BannerRepositoryType {
    func fetchBanners(forceRefresh: Bool) async throws -> [Banner]
}

final class BannerRepository: BannerRepositoryType {
    private let network: NetworkProviding
    private let storage: BannerStorageType

    init(network: NetworkProviding, storage: BannerStorageType) {
        self.network = network
        self.storage = storage
    }

    func fetchBanners(forceRefresh: Bool) async throws -> [Banner] {
        let cached = storage.fetchBanners()
        if !forceRefresh, !cached.isEmpty {
            return cached
        }

        do {
            let banners = try await network.request(.banners, type: [Banner].self)
            try storage.save(banners: banners)
            return banners
        } catch {
            let staleBanners = storage.fetchStaleBanners()
            if !staleBanners.isEmpty {
                return staleBanners
            }
            throw error
        }
    }
}
