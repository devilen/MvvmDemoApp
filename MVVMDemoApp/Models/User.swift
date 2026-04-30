import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let email: String
    let phone: String
    let address: String
    let avatarURL: String
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case address
        case avatarURL = "avatar_url"
        case lastUpdated = "last_updated"
    }
}
