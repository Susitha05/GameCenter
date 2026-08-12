import Foundation

/// A single saved Quiz Rush score (name + score + optional location),
/// separate from the other two games' plain local stores since this one
/// also tracks a player name.
struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let score: Int
    let date: Date
    let latitude: Double?
    let longitude: Double?

    init(
        id: UUID = UUID(),
        name: String,
        score: Int,
        date: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.score = score
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
    }
}
