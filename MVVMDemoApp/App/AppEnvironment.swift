import Foundation

final class AppEnvironment {
    let userRepository: UserRepositoryType
    let bannerRepository: BannerRepositoryType

    init(userRepository: UserRepositoryType, bannerRepository: BannerRepositoryType) {
        self.userRepository = userRepository
        self.bannerRepository = bannerRepository
    }

    static let live: AppEnvironment = {
        let networkProvider = NetworkProvider()
        let defaults = UserDefaults.standard

        let userStorage = UserStorage(store: defaults)
        let bannerStorage = BannerStorage(store: defaults)

        return AppEnvironment(
            userRepository: UserRepository(network: networkProvider, storage: userStorage),
            bannerRepository: BannerRepository(network: networkProvider, storage: bannerStorage)
        )
    }()
}
