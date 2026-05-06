import Foundation

final class AppEnvironment {
    let userRepository: UserRepositoryType
    let bannerRepository: BannerRepositoryType
    let monitor: AppMonitoring

    init(
        userRepository: UserRepositoryType,
        bannerRepository: BannerRepositoryType,
        monitor: AppMonitoring
    ) {
        self.userRepository = userRepository
        self.bannerRepository = bannerRepository
        self.monitor = monitor
    }

    static let live: AppEnvironment = {
        let monitor = DefaultAppMonitoring()
        let networkProvider = NetworkProvider(monitor: monitor)
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MVVMDemoAppCache", isDirectory: true)
        let cacheStore = FileCacheStore(directoryURL: cacheDirectory, monitor: monitor)

        let userStorage = UserStorage(cacheStore: cacheStore)
        let bannerStorage = BannerStorage(cacheStore: cacheStore)

        return AppEnvironment(
            userRepository: UserRepository(network: networkProvider, storage: userStorage, monitor: monitor),
            bannerRepository: BannerRepository(network: networkProvider, storage: bannerStorage, monitor: monitor),
            monitor: monitor
        )
    }()
}
