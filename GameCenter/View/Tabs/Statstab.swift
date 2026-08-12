import SwiftUI
import Charts

struct StatsTab: View {
    @StateObject private var viewModel = StatsVModel()
    @State private var selectedMode: GameMode = .tapFrenzy

    var body: some View {
        NavigationStack {
            List {
                // 1. Total Games Played & Total Marks
                Section("Overview") {
                    HStack {
                        StatColumn(title: "Games Played", value: "\(viewModel.totalGamesPlayed)")
                        Spacer()
                        StatColumn(title: "Total Marks", value: "\(viewModel.totalScoreAcrossAllModes)")
                    }
                    .padding(.vertical, 4)
                }

                // 2. Personal Bests for all 3 Games
                Section("Personal Bests") {
                    ForEach(GameMode.allCases) { mode in
                        HStack {
                            Label(mode.rawValue, systemImage: mode.icon)
                                .foregroundColor(mode.color)
                            Spacer()
                            Text("\(viewModel.personalBest(for: mode))")
                                .font(.headline)
                                .monospacedDigit()
                        }
                    }
                }

                // 3. Score History Charts for all 3 Games
                Section("Score History") {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    if viewModel.chartPoints(for: selectedMode).isEmpty {
                        Text("No games played yet in \(selectedMode.rawValue).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Chart(viewModel.chartPoints(for: selectedMode)) { point in
                            BarMark(
                                x: .value("Game", point.index),
                                y: .value("Score", point.score)
                            )
                            .foregroundStyle(selectedMode.color)
                        }
                        .frame(height: 180)
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Stats")
            .onAppear {
                // The three local stores are plain UserDefaults reads, not
                // live @Published stores the games push into — refresh here
                // so scores saved since the last visit actually show up.
                viewModel.refresh()
            }
        }
    }
}

private struct StatColumn: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
    }
}

#Preview {
    StatsTab()
}
