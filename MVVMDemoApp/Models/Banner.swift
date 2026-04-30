import Foundation

struct Banner: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let subtitle: String
    let imageURL: String
    let deeplink: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case imageURL = "image_url"
        case deeplink
    }
}
