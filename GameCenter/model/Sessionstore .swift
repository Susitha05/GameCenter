import Foundation

@MainActor
final class SessionStore: ObservableObject {

    static let shared = SessionStore()

    @Published private(set) var sessions: [GameSession] = []

    private let storageKey = "gameSessions"

    private init() {
        load()
    }

    func addSession(
        mode: GameMode,
        score: Int,
        coordinate: (latitude: Double, longitude: Double)? = nil
    ) {

        let session = GameSession(
            mode: mode,
            score: score,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude
        )

        sessions.append(session)
        save()
        print(
            "🎮 Session saved:",
            mode.rawValue,
            score,
            coordinate as Any
        )
    }

    func sessions(for mode: GameMode) -> [GameSession] {
        sessions.filter { $0.mode == mode }
    }

    func personalBest(for mode: GameMode) -> Int {
        sessions(for: mode)
            .map(\.score)
            .max() ?? 0
    }

    var totalGamesPlayed: Int {
        sessions.count
    }

    var recentSessions: [GameSession] {
        sessions.sorted {
            $0.timestamp > $1.timestamp
        }
    }

    func resetAll() {
        sessions.removeAll()
        save()
    }

    private func load() {

        guard
            let data = UserDefaults.standard.data(
                forKey: storageKey
            ),
            let decoded = try? JSONDecoder().decode(
                [GameSession].self,
                from: data
            )
        else {
            return
        }

        sessions = decoded
    }

    private func save() {

        guard let data = try? JSONEncoder().encode(sessions) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: storageKey
        )
    }
}
