import Foundation

struct User: Codable, Identifiable {
    var id: UUID
    var username: String
    var name: String?
    var unitsPreference: String?
    var role: String
}
