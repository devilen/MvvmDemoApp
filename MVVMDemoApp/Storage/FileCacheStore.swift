import Foundation

final class FileCacheStore {
    private let directoryURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let monitor: AppMonitoring

    init(
        directoryURL: URL,
        fileManager: FileManager = .default,
        monitor: AppMonitoring = NoOpAppMonitoring.shared
    ) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager
        self.monitor = monitor

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func save<T: Codable>(_ value: CachedEntry<T>, filename: String) throws {
        let span = monitor.beginSpan(
            "save_cache",
            domain: .storage,
            metadata: ["filename": filename]
        )
        do {
            try createDirectoryIfNeeded()
            let data = try encoder.encode(value)
            try data.write(to: fileURL(for: filename), options: .atomic)
            span.succeed(metadata: ["bytes": "\(data.count)"])
        } catch {
            let storageError = AppError.storage(error.localizedDescription)
            span.fail(storageError)
            throw storageError
        }
    }

    func load<T: Codable>(_ type: CachedEntry<T>.Type, filename: String) -> CachedEntry<T>? {
        let span = monitor.beginSpan(
            "load_cache",
            domain: .storage,
            metadata: ["filename": filename]
        )
        let fileURL = fileURL(for: filename)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            span.succeed(metadata: ["cacheHit": "false", "reason": "missing"])
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            span.succeed(metadata: ["cacheHit": "false", "reason": "unreadable"])
            return nil
        }

        guard let entry = try? decoder.decode(type, from: data) else {
            span.succeed(metadata: ["cacheHit": "false", "reason": "decodeFailed"])
            return nil
        }

        span.succeed(metadata: ["cacheHit": "true", "bytes": "\(data.count)"])
        return entry
    }

    private func fileURL(for filename: String) -> URL {
        directoryURL.appendingPathComponent(filename)
    }

    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
}
