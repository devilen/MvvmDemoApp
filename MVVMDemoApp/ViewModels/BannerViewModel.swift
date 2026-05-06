import Foundation

@MainActor
final class BannerViewModel: ObservableObject {
    @Published private(set) var banners: [Banner] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: BannerRepositoryType
    private let monitor: AppMonitoring
    private var loadTask: Task<Void, Never>?

    init(repository: BannerRepositoryType, monitor: AppMonitoring = NoOpAppMonitoring.shared) {
        self.repository = repository
        self.monitor = monitor
    }

    func load(forceRefresh: Bool = false) {
        guard !isLoading else {
            monitor.log(
                .debug,
                domain: .viewModel,
                message: "banner load ignored while request is in flight",
                metadata: ["forceRefresh": "\(forceRefresh)"]
            )
            return
        }

        isLoading = true
        errorMessage = nil
        let span = monitor.beginSpan(
            "load_banner_view_model",
            domain: .viewModel,
            metadata: ["forceRefresh": "\(forceRefresh)"]
        )

        loadTask?.cancel()
        loadTask = Task {
            do {
                let banners = try await repository.fetchBanners(forceRefresh: forceRefresh)
                self.banners = banners
                span.succeed(metadata: ["count": "\(self.banners.count)"])
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
