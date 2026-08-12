import SwiftUI
import CoreLocation

/// Persists Quiz Rush leaderboard entries (name + score + optional location)
/// to UserDefaults as JSON. Local storage only.
@MainActor
final class LeaderboardStore: ObservableObject {
    static let shared = LeaderboardStore()

    @Published private(set) var entries: [LeaderboardEntry] = []

    private let storageKey = "quizRushLeaderboardEntries"
    private let maxStoredEntries = 100

    private init() {
        load()
    }

    /// Adds a new score, tagging it with whatever location LocationService
    /// currently has (if any).
    func addEntry(name: String, score: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "Player" : String(trimmed.prefix(20))
        let coordinate = LocationService.shared.coordinateForSession

        entries.append(LeaderboardEntry(
            name: finalName,
            score: score,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude
        ))
        trimIfNeeded()
        save()
    }

    func topEntries(limit: Int = 20) -> [LeaderboardEntry] {
        Array(entries.sorted { $0.score > $1.score }.prefix(limit))
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    private func trimIfNeeded() {
        guard entries.count > maxStoredEntries else { return }
        entries = Array(entries.sorted { $0.score > $1.score }.prefix(maxStoredEntries))
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
            return
        }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
