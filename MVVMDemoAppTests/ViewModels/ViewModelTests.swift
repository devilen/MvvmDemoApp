import Foundation
import Testing
@testable import MVVMDemoApp

@MainActor
struct ViewModelTests {
    @Test
    func userViewModelLoadsUserOnSuccess() async {
        let expectedUser = SampleData.user()
        let repository = MockUserRepository(result: .success(expectedUser))
        let viewModel = UserViewModel(repository: repository)

        viewModel.load()
        await waitUntilFinished(viewModel)

        #expect(viewModel.user == expectedUser)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
        #expect(repository.forceRefreshValues == [false])
    }

    @Test
    func userViewModelExposesErrorOnFailure() async {
        let repository = MockUserRepository(result: .failure(AppError.network("offline")))
        let viewModel = UserViewModel(repository: repository)

        viewModel.load(forceRefresh: true)
        await waitUntilFinished(viewModel)

        #expect(viewModel.user == nil)
        #expect(viewModel.errorMessage == AppError.network("offline").localizedDescription)
        #expect(repository.forceRefreshValues == [true])
    }

    @Test
    func bannerViewModelLoadsBannersOnSuccess() async {
        let expectedBanners = SampleData.banners
        let repository = MockBannerRepository(result: .success(expectedBanners))
        let viewModel = BannerViewModel(repository: repository)

        viewModel.load()
        await waitUntilFinished(viewModel)

        #expect(viewModel.banners == expectedBanners)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test
    func bannerViewModelIgnoresCancellationError() async {
        let repository = MockBannerRepository(result: .failure(AppError.cancelled))
        let viewModel = BannerViewModel(repository: repository)

        viewModel.load(forceRefresh: true)
        await waitUntilFinished(viewModel)

        #expect(viewModel.banners.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    private func waitUntilFinished(_ viewModel: UserViewModel) async {
        while viewModel.isLoading {
            await Task.yield()
        }
    }

    private func waitUntilFinished(_ viewModel: BannerViewModel) async {
        while viewModel.isLoading {
            await Task.yield()
        }
    }
}

private enum SampleData {
    static func user() -> User {
        User(
            id: 1,
            name: "Promise",
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

private final class MockUserRepository: UserRepositoryType {
    let result: Result<User, Error>
    private(set) var forceRefreshValues: [Bool] = []

    init(result: Result<User, Error>) {
        self.result = result
    }

    func fetchUser(forceRefresh: Bool) async throws -> User {
        forceRefreshValues.append(forceRefresh)
        return try result.get()
    }
}

private final class MockBannerRepository: BannerRepositoryType {
    let result: Result<[Banner], Error>
    private(set) var forceRefreshValues: [Bool] = []

    init(result: Result<[Banner], Error>) {
        self.result = result
    }

    func fetchBanners(forceRefresh: Bool) async throws -> [Banner] {
        forceRefreshValues.append(forceRefresh)
        return try result.get()
    }
}
