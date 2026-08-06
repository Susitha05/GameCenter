//
//  ScoreboardView.swift
//  GameCenter
//

import SwiftUI
import CoreLocation

// MARK: - Combined record + loader

/// One entry on the combined scoreboard — wraps whichever game's own record
/// it came from, tagged with which mode it belongs to. Doesn't change how
/// each game stores its own scores; it just reads all three and merges them
/// for display here.
struct CombinedScoreRecord: Identifiable {
    let id: UUID
    let mode: GameMode
    let score: Int
    let date: Date
    /// Only Quiz Rush entries have a name attached (via LeaderboardStore).
    let name: String?
    let latitude: Double?
    let longitude: Double?

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }
}

enum CombinedScoreboard {
    static func loadAll() -> [CombinedScoreRecord] {
        let tapFrenzy = TapFrenzyLocalStore.load().map {
            CombinedScoreRecord(
                id: $0.id, mode: .tapFrenzy, score: $0.score, date: $0.date,
                name: nil, latitude: $0.latitude, longitude: $0.longitude
            )
        }
        let lightItUp = LightItUpLocalStore.load().map {
            CombinedScoreRecord(
                id: $0.id, mode: .lightItUp, score: $0.score, date: $0.date,
                name: nil, latitude: $0.latitude, longitude: $0.longitude
            )
        }
        // Quiz Rush still uses the named LeaderboardStore (singleton, instance
        // methods), not a plain local store, so it's read differently here.
        let quizRush = LeaderboardStore.shared.entries.map {
            CombinedScoreRecord(
                id: $0.id, mode: .quizRush, score: $0.score, date: $0.date,
                name: $0.name, latitude: $0.latitude, longitude: $0.longitude
            )
        }
        return tapFrenzy + lightItUp + quizRush
    }

    static func clearAll() {
        TapFrenzyLocalStore.clear()
        LightItUpLocalStore.clear()
        LeaderboardStore.shared.clearAll()
    }
}

// MARK: - View

struct ScoreboardView: View {
    @State private var allRecords: [CombinedScoreRecord] = []
    @State private var selectedMode: GameMode?
    @State private var showClearConfirmation = false

    private var filteredRecords: [CombinedScoreRecord] {
        let base = selectedMode == nil ? allRecords : allRecords.filter { $0.mode == selectedMode }
        return base.sorted { $0.score > $1.score }
    }

    private func bestScore(for mode: GameMode) -> Int {
        allRecords.filter { $0.mode == mode }.map(\.score).max() ?? 0
    }

    var body: some View {
        List {
            Section {
                Picker("Mode", selection: $selectedMode) {
                    Text("All Games").tag(GameMode?.none)
                    ForEach(GameMode.allCases) { mode in
                        Text(mode.rawValue).tag(GameMode?.some(mode))
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowSeparator(.hidden)

            Section("Personal Bests") {
                ForEach(GameMode.allCases) { mode in
                    HStack {
                        Label(mode.rawValue, systemImage: mode.icon)
                            .foregroundColor(mode.color)
                        Spacer()
                        Text("\(bestScore(for: mode))")
                            .font(.headline)
                            .monospacedDigit()
                    }
                }
            }

            if filteredRecords.isEmpty {
                emptyState
            } else {
                Section(selectedMode == nil ? "All Scores" : "\(selectedMode!.rawValue) Scores") {
                    ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
                        row(rank: index + 1, record: record)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Scoreboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !allRecords.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All", role: .destructive) {
                        showClearConfirmation = true
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear every saved score?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Everything", role: .destructive) {
                CombinedScoreboard.clearAll()
                allRecords = []
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every saved score from all three games. This can't be undone.")
        }
        .onAppear {
            allRecords = CombinedScoreboard.loadAll()
        }
    }

    private func row(rank: Int, record: CombinedScoreRecord) -> some View {
        HStack(spacing: 12) {
            Text(rankLabel(rank))
                .font(.headline)
                .foregroundColor(rank <= 3 ? .orange : .secondary)
                .frame(width: 36, alignment: .leading)

            Image(systemName: record.mode.icon)
                .foregroundColor(record.mode.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                if let name = record.name {
                    Text(name)
                        .font(.body.weight(.medium))
                    Text("\(record.score) points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(record.score) points")
                        .font(.body.weight(.medium))
                }
                HStack(spacing: 6) {
                    if selectedMode == nil {
                        Text(record.mode.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("·")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No scores yet")
                .font(.headline)
            Text("Play any of the three games to see it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
    }
}

#Preview {
    NavigationStack { ScoreboardView() }
}
