import Foundation

enum AppError: LocalizedError {
    case cancelled
    case network(String)
    case storage(String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "请求已取消"
        case .network(let message):
            return "网络请求失败：\(message)"
        case .storage(let message):
            return "本地存储失败：\(message)"
        case .invalidData:
            return "返回数据解析失败"
        }
    }
}
