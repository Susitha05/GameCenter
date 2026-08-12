import Foundation
import Combine

/// One data point for the per-mode bar chart — the Nth game played in that
/// mode, and the score it got.
struct ModeChartPoint: Identifiable {
    let id = UUID()
    let index: Int
    let score: Int
}

/// Reads from `SessionStore` and exposes everything the Stats tab needs:
/// totals, personal bests per mode, a recent-games list, and chart-ready
/// data points per mode. Keeps all aggregation logic out of the view.
@MainActor
final class StatsViewModel: ObservableObject {
    @Published private(set) var sessions: [GameSession] = []

    private let store: SessionStore
    private var cancellable: AnyCancellable?

    init(store: SessionStore = .shared) {
        self.store = store
        sessions = store.sessions
        cancellable = store.$sessions.sink { [weak self] updated in
            self?.sessions = updated
        }
    }

    var totalGamesPlayed: Int { sessions.count }

    var totalScoreAcrossAllModes: Int {
        sessions.reduce(0) { $0 + $1.score }
    }

    func gamesPlayed(for mode: GameMode) -> Int {
        sessions.filter { $0.mode == mode }.count
    }

    func personalBest(for mode: GameMode) -> Int {
        sessions.filter { $0.mode == mode }.map(\.score).max() ?? 0
    }

    /// Chart-ready points for a mode, in chronological order.
    func chartPoints(for mode: GameMode) -> [ModeChartPoint] {
        sessions
            .filter { $0.mode == mode }
            .sorted { $0.timestamp < $1.timestamp }
            .enumerated()
            .map { ModeChartPoint(index: $0.offset + 1, score: $0.element.score) }
    }

    var recentSessions: [GameSession] {
        Array(sessions.sorted { $0.timestamp > $1.timestamp }.prefix(10))
    }

    func resetAllStats() {
        store.resetAll()
    }
}
