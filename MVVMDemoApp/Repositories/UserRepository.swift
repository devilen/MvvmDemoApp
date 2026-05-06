import Foundation

protocol UserRepositoryType {
    func fetchUser(forceRefresh: Bool) async throws -> User
}

final class UserRepository: UserRepositoryType {
    private let network: NetworkProviding
    private let storage: UserStorageType
    private let monitor: AppMonitoring

    init(
        network: NetworkProviding,
        storage: UserStorageType,
        monitor: AppMonitoring = NoOpAppMonitoring.shared
    ) {
        self.network = network
        self.storage = storage
        self.monitor = monitor
    }

    func fetchUser(forceRefresh: Bool) async throws -> User {
        let span = monitor.beginSpan(
            "fetch_user",
            domain: .repository,
            metadata: ["forceRefresh": "\(forceRefresh)"]
        )
        if !forceRefresh, let cached = storage.fetchUser() {
            span.succeed(metadata: ["source": "freshCache"])
            return cached
        }

        do {
            let user = try await network.request(.userDetail, type: User.self)
            try storage.save(user: user)
            span.succeed(metadata: ["source": "network"])
            return user
        } catch {
            if let staleUser = storage.fetchStaleUser() {
                span.succeed(metadata: ["source": "staleCache", "fallback": "true"])
                return staleUser
            }
            span.fail(error)
            throw error
        }
    }
}
