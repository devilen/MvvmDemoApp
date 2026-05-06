import Foundation
import OSLog

enum MonitoringLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case error = "ERROR"
}

enum MonitoringDomain: String {
    case network
    case storage
    case repository
    case viewModel
}

struct MonitoringSpan {
    private let onFinish: (MonitoringOutcome, [String: String]) -> Void

    fileprivate init(onFinish: @escaping (MonitoringOutcome, [String: String]) -> Void) {
        self.onFinish = onFinish
    }

    func succeed(metadata: [String: String] = [:]) {
        onFinish(.success, metadata)
    }

    func fail(_ error: Error, metadata: [String: String] = [:]) {
        onFinish(.failure(error), metadata)
    }
}

protocol AppMonitoring {
    func log(_ level: MonitoringLevel, domain: MonitoringDomain, message: String, metadata: [String: String])
    func beginSpan(_ name: String, domain: MonitoringDomain, metadata: [String: String]) -> MonitoringSpan
}

final class DefaultAppMonitoring: AppMonitoring {
    private let logger: Logger

    init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.promise.MVVMDemoApp",
        category: String = "monitoring"
    ) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func log(_ level: MonitoringLevel, domain: MonitoringDomain, message: String, metadata: [String: String] = [:]) {
        emit(level, formattedMessage(for: domain, message: message, metadata: metadata))
    }

    func beginSpan(_ name: String, domain: MonitoringDomain, metadata: [String: String] = [:]) -> MonitoringSpan {
        let startedAt = Date()
        log(.info, domain: domain, message: "\(name) started", metadata: metadata)

        return MonitoringSpan { [weak self] outcome, extraMetadata in
            guard let self else { return }

            var mergedMetadata = metadata
            extraMetadata.forEach { mergedMetadata[$0.key] = $0.value }
            mergedMetadata["durationMs"] = String(format: "%.2f", Date().timeIntervalSince(startedAt) * 1000)

            switch outcome {
            case .success:
                self.log(.info, domain: domain, message: "\(name) finished", metadata: mergedMetadata)
            case .failure(let error):
                mergedMetadata["error"] = error.localizedDescription
                self.log(.error, domain: domain, message: "\(name) failed", metadata: mergedMetadata)
            }
        }
    }

    private func formattedMessage(for domain: MonitoringDomain, message: String, metadata: [String: String]) -> String {
        let metadataString = metadata.isEmpty
            ? ""
            : " | " + metadata
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")

        return "[\(domain.rawValue)] \(message)\(metadataString)"
    }

    private func emit(_ level: MonitoringLevel, _ message: String) {
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        }
    }
}

final class NoOpAppMonitoring: AppMonitoring {
    static let shared = NoOpAppMonitoring()

    private init() {}

    func log(_ level: MonitoringLevel, domain: MonitoringDomain, message: String, metadata: [String : String]) {}

    func beginSpan(_ name: String, domain: MonitoringDomain, metadata: [String : String]) -> MonitoringSpan {
        MonitoringSpan { _, _ in }
    }
}

private enum MonitoringOutcome {
    case success
    case failure(Error)
}
