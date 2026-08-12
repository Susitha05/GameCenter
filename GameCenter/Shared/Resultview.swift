import SwiftUI

/// Shared "round over" screen used by all three modes. Always shows score,
/// personal best, a Play Again button, and a `ShareLink`. When `mode ==
/// .quizRush`, it additionally offers name entry to save the score to the
/// local leaderboard — the other two modes don't have a leaderboard.
struct ResultView: View {
    let title: String
    let mode: GameMode
    let score: Int
    let highScore: Int
    let onReplay: () -> Void

    @ObservedObject private var leaderboard = LeaderboardStore.shared
    @AppStorage("playerDisplayName") private var savedName: String = ""
    @State private var name: String = ""
    @State private var didSave = false
    @State private var showLeaderboard = false

    private var shareText: String {
        "I just scored \(score) on \(mode.rawValue) — beat that."
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            ScoreBadge(label: "Score", value: score, color: mode.color)

            Text("Best: \(highScore)")
                .foregroundColor(.secondary)

            if mode == .quizRush {
                leaderboardSection
            }

            VStack(spacing: 10) {
                Button("Play Again", action: onReplay)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 12) {
                    ShareLink(item: shareText) {
                        Label("Share Result", systemImage: "square.and.arrow.up.fill")
                            .frame(maxWidth: .infinity)
                    }
                   

                    if mode == .quizRush {
                        Button {
                            showLeaderboard = true
                        } label: {
                            Label("Leaderboard", systemImage: "trophy")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(32)
        .background(.thinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .onAppear {
            if name.isEmpty { name = savedName }
        }
        .sheet(isPresented: $showLeaderboard) {
            NavigationStack { LeaderboardView() }
        }
    }

    private var leaderboardSection: some View {
        Group {
            if didSave {
                Label("Saved to leaderboard", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
            } else {
                VStack(spacing: 8) {
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                    Button("Save Score") { saveScore() }
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func saveScore() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        leaderboard.addEntry(name: trimmed, score: score)
        savedName = trimmed
        didSave = true
    }
}

