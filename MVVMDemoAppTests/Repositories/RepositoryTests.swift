import Foundation
import Testing
@testable import MVVMDemoApp

struct RepositoryTests {
    @Test
    func userRepositoryReturnsFreshCacheBeforeRequestingNetwork() async throws {
        let cachedUser = SampleData.user(name: "Cached User")
        let network = MockNetworkProvider()
        let storage = MockUserStorage(freshUser: cachedUser)
        let repository = UserRepository(network: network, storage: storage)

        let user = try await repository.fetchUser(forceRefresh: false)

        #expect(user == cachedUser)
        #expect(network.requestedTargets.isEmpty)
        #expect(storage.savedUser == nil)
    }

    @Test
    func userRepositoryFallsBackToStaleCacheWhenRequestFails() async throws {
        let staleUser = SampleData.user(name: "Stale User")
        let network = MockNetworkProvider()
        network.userResult = .failure(AppError.network("offline"))
        let storage = MockUserStorage(staleUser: staleUser)
        let repository = UserRepository(network: network, storage: storage)

        let user = try await repository.fetchUser(forceRefresh: true)

        #expect(user == staleUser)
        #expect(network.requestedTargets.count == 1)
        if case .userDetail? = network.requestedTargets.first {
            #expect(Bool(true))
        } else {
            Issue.record("Expected first request target to be userDetail")
        }
    }

    @Test
    func bannerRepositorySavesNetworkResultWhenCacheIsEmpty() async throws {
        let banners = SampleData.banners
        let network = MockNetworkProvider()
        network.bannerResult = .success(banners)
        let storage = MockBannerStorage()
        let repository = BannerRepository(network: network, storage: storage)

        let result = try await repository.fetchBanners(forceRefresh: false)

        #expect(result == banners)
        #expect(storage.savedBanners == banners)
        #expect(network.requestedTargets.count == 1)
        if case .banners? = network.requestedTargets.first {
            #expect(Bool(true))
        } else {
            Issue.record("Expected first request target to be banners")
        }
    }

    @Test
    func bannerRepositoryThrowsWhenRequestFailsWithoutFallbackCache() async {
        let network = MockNetworkProvider()
        network.bannerResult = .failure(AppError.network("offline"))
        let storage = MockBannerStorage()
        let repository = BannerRepository(network: network, storage: storage)

        await #expect(throws: AppError.self) {
            _ = try await repository.fetchBanners(forceRefresh: true)
        }
    }
}

private enum SampleData {
    static func user(name: String = "Promise") -> User {
        User(
            id: 1,
            name: name,
            email: "promise@example.com",
            phone: "13800000000",
            address: "Shenzhen",
            avatarURL: "https://example.com/avatar.png",
            lastUpdated: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    static let banners: [Banner] = [
        Banner(
            id: 1,
            title: "Spring Sale",
            subtitle: "50% off",
            imageURL: "https://example.com/banner.png",
            deeplink: "mvvm-demo://banner/1"
        )
    ]
}

private final class MockNetworkProvider: NetworkProviding {
    var userResult: Result<User, Error> = .success(SampleData.user())
    var bannerResult: Result<[Banner], Error> = .success(SampleData.banners)
    private(set) var requestedTargets: [DemoAPI] = []

    func request<T>(_ target: DemoAPI, type: T.Type) async throws -> T where T : Decodable {
        requestedTargets.append(target)

        switch target {
        case .userDetail:
            return try userResult.get() as! T
        case .banners:
            return try bannerResult.get() as! T
        }
    }
}

private final class MockUserStorage: UserStorageType {
    let freshUser: User?
    let staleUser: User?
    private(set) var savedUser: User?

    init(freshUser: User? = nil, staleUser: User? = nil) {
        self.freshUser = freshUser
        self.staleUser = staleUser
    }

    func save(user: User) throws {
        savedUser = user
    }

    func fetchUser() -> User? {
        freshUser
    }

    func fetchStaleUser() -> User? {
        staleUser
    }
}

private final class MockBannerStorage: BannerStorageType {
    let freshBanners: [Banner]
    let staleBanners: [Banner]
    private(set) var savedBanners: [Banner]?

    init(freshBanners: [Banner] = [], staleBanners: [Banner] = []) {
        self.freshBanners = freshBanners
        self.staleBanners = staleBanners
    }

    func save(banners: [Banner]) throws {
        savedBanners = banners
    }

    func fetchBanners() -> [Banner] {
        freshBanners
    }

    func fetchStaleBanners() -> [Banner] {
        staleBanners
    }
}
