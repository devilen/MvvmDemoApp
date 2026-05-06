import Foundation

@MainActor
final class UserViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: UserRepositoryType
    private let monitor: AppMonitoring
    private var loadTask: Task<Void, Never>?

    init(repository: UserRepositoryType, monitor: AppMonitoring = NoOpAppMonitoring.shared) {
        self.repository = repository
        self.monitor = monitor
    }

    func load(forceRefresh: Bool = false) {
        guard !isLoading else {
            monitor.log(
                .debug,
                domain: .viewModel,
                message: "user load ignored while request is in flight",
                metadata: ["forceRefresh": "\(forceRefresh)"]
            )
            return
        }

        isLoading = true
        errorMessage = nil
        let span = monitor.beginSpan(
            "load_user_view_model",
            domain: .viewModel,
            metadata: ["forceRefresh": "\(forceRefresh)"]
        )

        loadTask?.cancel()
        loadTask = Task {
            do {
                let user = try await repository.fetchUser(forceRefresh: forceRefresh)
                self.user = user
                span.succeed(metadata: ["hasUser": "\(self.user != nil)"])
            } catch {
                if !Task.isCancelled, !isCancellationError(error) {
                    self.errorMessage = error.localizedDescription
                }
                span.fail(error)
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
