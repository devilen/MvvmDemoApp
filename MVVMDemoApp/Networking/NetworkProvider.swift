import Foundation
import Moya

protocol NetworkProviding {
    func request<T: Decodable>(_ target: DemoAPI, type: T.Type) async throws -> T
}

final class NetworkProvider: NetworkProviding {
    private let provider: MoyaProvider<DemoAPI>
    private let decoder: JSONDecoder
    private let monitor: AppMonitoring

    init(
        stubBehavior: @escaping MoyaProvider<DemoAPI>.StubClosure = MoyaProvider.immediatelyStub,
        monitor: AppMonitoring = NoOpAppMonitoring.shared
    ) {
        self.provider = MoyaProvider<DemoAPI>(stubClosure: stubBehavior)
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.monitor = monitor
    }

    func request<T: Decodable>(_ target: DemoAPI, type: T.Type) async throws -> T {
        let span = monitor.beginSpan(
            "network_request",
            domain: .network,
            metadata: [
                "target": String(describing: target),
                "responseType": String(describing: type)
            ]
        )
        let requestToken = RequestToken()
        do {
            let response = try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Response, Error>) in
                    guard !Swift.Task.isCancelled else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }

                    let cancellable = provider.request(target) { result in
                        switch result {
                        case .success(let response):
                            continuation.resume(returning: response)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    requestToken.set(cancellable)
                }
            } onCancel: {
                requestToken.cancel()
                monitor.log(
                    .debug,
                    domain: .network,
                    message: "request cancelled",
                    metadata: ["target": String(describing: target)]
                )
            }

            let filtered = try response.filterSuccessfulStatusCodes()
            let decoded = try decoder.decode(T.self, from: filtered.data)
            span.succeed(metadata: ["statusCode": "\(filtered.statusCode)"])
            return decoded
        } catch {
            let mappedError = Self.mapError(error)
            span.fail(mappedError)
            throw mappedError
        }
    }

    private static func mapError(_ error: Error) -> AppError {
        if error is CancellationError {
            return .cancelled
        }

        if let appError = error as? AppError {
            return appError
        }

        guard let moyaError = error as? MoyaError else {
            return .network(error.localizedDescription)
        }

        switch moyaError {
        case .underlying(let underlyingError, _) where underlyingError is CancellationError:
            return .cancelled
        case .objectMapping, .jsonMapping, .stringMapping:
            return .invalidData
        case .statusCode(let response):
            return .network("状态码 \(response.statusCode)")
        default:
            return .network(moyaError.localizedDescription)
        }
    }
}

private final class RequestToken: @unchecked Sendable {
    private let lock = NSLock()
    private var cancellable: Cancellable?

    func set(_ cancellable: Cancellable) {
        lock.lock()
        self.cancellable = cancellable
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        let cancellable = self.cancellable
        lock.unlock()
        cancellable?.cancel()
    }
}
