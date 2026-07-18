import SwiftUI

/// Quiz Rush leaderboard: ranked list of saved scores.
struct LeaderboardView: View {
    @ObservedObject private var store = LeaderboardStore.shared
    @Environment(\.dismiss) private var dismiss

    private var entries: [LeaderboardEntry] {
        store.topEntries(limit: 20)
    }

    var body: some View {
        List {
            if entries.isEmpty {
                emptyState
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    row(rank: index + 1, entry: entry)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Quiz Rush Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func row(rank: Int, entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text(rankLabel(rank))
                .font(.headline)
                .foregroundColor(rank <= 3 ? .orange : .secondary)
                .frame(width: 36, alignment: .leading)

            Text(entry.name)
                .font(.body.weight(.medium))

            Spacer()

            Text("\(entry.score)")
                .font(.headline)
                .monospacedDigit()
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
            Text("Play a round of Quiz Rush and save your score to see it here.")
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
    NavigationStack { LeaderboardView() }
}
