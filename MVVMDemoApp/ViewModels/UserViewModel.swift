import Foundation

@MainActor
final class UserViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: UserRepositoryType
    private var loadTask: Task<Void, Never>?

    init(repository: UserRepositoryType) {
        self.repository = repository
    }

    func load(forceRefresh: Bool = false) {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        loadTask?.cancel()
        loadTask = Task {
            do {
                let user = try await repository.fetchUser(forceRefresh: forceRefresh)
                self.user = user
            } catch {
                if !Task.isCancelled, !isCancellationError(error) {
                    self.errorMessage = error.localizedDescription
                }
            }
            self.isLoading = false
        }
    }

    private func isCancellationError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if case AppError.cancelled = error {
            return true
        }

        return false
    }
}
