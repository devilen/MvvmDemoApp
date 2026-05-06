import Foundation

protocol BannerRepositoryType {
    func fetchBanners(forceRefresh: Bool) async throws -> [Banner]
}

final class BannerRepository: BannerRepositoryType {
    private let network: NetworkProviding
    private let storage: BannerStorageType
    private let monitor: AppMonitoring

    init(
        network: NetworkProviding,
        storage: BannerStorageType,
        monitor: AppMonitoring = NoOpAppMonitoring.shared
    ) {
        self.network = network
        self.storage = storage
        self.monitor = monitor
    }

    func fetchBanners(forceRefresh: Bool) async throws -> [Banner] {
        let span = monitor.beginSpan(
            "fetch_banners",
            domain: .repository,
            metadata: ["forceRefresh": "\(forceRefresh)"]
        )
        let cached = storage.fetchBanners()
        if !forceRefresh, !cached.isEmpty {
            span.succeed(metadata: ["source": "freshCache", "count": "\(cached.count)"])
            return cached
        }

        do {
            let banners = try await network.request(.banners, type: [Banner].self)
            try storage.save(banners: banners)
            span.succeed(metadata: ["source": "network", "count": "\(banners.count)"])
            return banners
        } catch {
            let staleBanners = storage.fetchStaleBanners()
            if !staleBanners.isEmpty {
                span.succeed(metadata: ["source": "staleCache", "fallback": "true", "count": "\(staleBanners.count)"])
                return staleBanners
            }
            span.fail(error)
            throw error
        }
    }
}
