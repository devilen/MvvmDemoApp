import Foundation

protocol UserRepositoryType {
    func fetchUser(forceRefresh: Bool) async throws -> User
}

final class UserRepository: UserRepositoryType {
    private let network: NetworkProviding
    private let storage: UserStorageType

    init(network: NetworkProviding, storage: UserStorageType) {
        self.network = network
        self.storage = storage
    }

    func fetchUser(forceRefresh: Bool) async throws -> User {
        if !forceRefresh, let cached = storage.fetchUser() {
            return cached
        }

        do {
            let user = try await network.request(.userDetail, type: User.self)
            try storage.save(user: user)
            return user
        } catch {
            if let staleUser = storage.fetchStaleUser() {
                return staleUser
            }
            throw error
        }
    }
}
