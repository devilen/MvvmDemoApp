import Foundation
import Moya

enum DemoAPI {
    case userDetail
    case banners
}

extension DemoAPI: TargetType {
    static let baseURLString = "https://example.com"

    var baseURL: URL {
        URL(string: DemoAPI.baseURLString)!
    }

    var path: String {
        switch self {
        case .userDetail:
            return "/api/user"
        case .banners:
            return "/api/banners"
        }
    }

    var method: Moya.Method {
        .get
    }

    var task: Task {
        .requestPlain
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }

    var sampleData: Data {
        switch self {
        case .userDetail:
            return Data("""
            {
              "id": 1001,
              "name": "Promise",
              "email": "promise@example.com",
              "phone": "+86 13800000000",
              "address": "Shenzhen Nanshan",
              "avatar_url": "https://example.com/images/avatar.png",
              "last_updated": "2026-04-08T12:00:00Z"
            }
            """.utf8)
        case .banners:
            return Data("""
            [
              {
                "id": 1,
                "title": "春季大促",
                "subtitle": "精选商品低至五折",
                "image_url": "https://example.com/images/banner1.png",
                "deeplink": "mvvm-demo://banner/1"
              },
              {
                "id": 2,
                "title": "会员专区",
                "subtitle": "立即查看专属权益",
                "image_url": "https://example.com/images/banner2.png",
                "deeplink": "mvvm-demo://banner/2"
              }
            ]
            """.utf8)
        }
    }
}
