import SwiftUI

// MARK: - Helper Models for the UI
struct ChartPoint: Identifiable {
    let id = UUID()
    let index: Int
    let score: Int
}

// MARK: - Main View Model
class StatsVModel: ObservableObject {
    @Published var totalGamesPlayed: Int = 0
    @Published var totalScoreAcrossAllModes: Int = 0

    // Keeping local copies of the records so the view doesn't have to keep fetching them
    private var tapRecords: [TapFrenzyScoreRecord] = []
    private var lightUpRecords: [LightItUpScoreRecord] = []
    private var quizRecords: [LeaderboardEntry] = []

    /// Pulls the latest data from all three local stores
    @MainActor func refresh() {
        // 1. Fetch data from the stores you provided
        tapRecords = TapFrenzyLocalStore.load()
        lightUpRecords = LightItUpLocalStore.load()
        // Pulling up to 100 entries for Quiz Rush stats
        quizRecords = LeaderboardStore.shared.topEntries(limit: 100)

        // 2. Calculate Total Games Played
        totalGamesPlayed = tapRecords.count + lightUpRecords.count + quizRecords.count

        // 3. Calculate Total Marks (Scores)
        let tapTotal = tapRecords.reduce(0) { $0 + $1.score }
        let lightUpTotal = lightUpRecords.reduce(0) { $0 + $1.score }
        let quizTotal = quizRecords.reduce(0) { $0 + $1.score }
        
        totalScoreAcrossAllModes = tapTotal + lightUpTotal + quizTotal
    }

    /// Returns the highest score for a specific game
    func personalBest(for mode: GameMode) -> Int {
        switch mode {
        case .tapFrenzy:
            return tapRecords.map(\.score).max() ?? 0
        case .lightItUp: // Fixed to match your enum
            return lightUpRecords.map(\.score).max() ?? 0
        case .quizRush:
            return quizRecords.map(\.score).max() ?? 0
        }
    }

    /// Formats the score arrays so the SwiftUI Chart can read them
    func chartPoints(for mode: GameMode) -> [ChartPoint] {
        switch mode {
        case .tapFrenzy:
            // Sort oldest to newest so the chart goes left to right over time
            let chronological = tapRecords.sorted { $0.date < $1.date }
            return chronological.enumerated().map { ChartPoint(index: $0.offset + 1, score: $0.element.score) }
            
        case .lightItUp: // Fixed to match your enum
            let chronological = lightUpRecords.sorted { $0.date < $1.date }
            return chronological.enumerated().map { ChartPoint(index: $0.offset + 1, score: $0.element.score) }
            
        case .quizRush:
            // Quiz Rush entries might not have dates, so we'll just chart them as they appear
            return quizRecords.enumerated().map { ChartPoint(index: $0.offset + 1, score: $0.element.score) }
        }
    }
}
