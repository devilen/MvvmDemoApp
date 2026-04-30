import Foundation

@MainActor
final class BannerViewModel: ObservableObject {
    @Published private(set) var banners: [Banner] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: BannerRepositoryType
    private var loadTask: Task<Void, Never>?

    init(repository: BannerRepositoryType) {
        self.repository = repository
    }

    func load(forceRefresh: Bool = false) {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        loadTask?.cancel()
        loadTask = Task {
            do {
                let banners = try await repository.fetchBanners(forceRefresh: forceRefresh)
                self.banners = banners
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
