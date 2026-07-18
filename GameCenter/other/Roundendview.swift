import SwiftUI

/// Quiz Rush's "round over" card: score summary, name entry to save to the
/// local leaderboard, then Play Again / view the Leaderboard.
struct RoundEndView: View {
    let title: String
    let score: Int
    let highScore: Int
    let onReplay: () -> Void

    @ObservedObject private var store = LeaderboardStore.shared
    @AppStorage("playerDisplayName") private var savedName: String = ""
    @State private var name: String = ""
    @State private var didSave = false
    @State private var showLeaderboard = false

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Score: \(score)")
                .font(.title2)
            Text("Best: \(highScore)")
                .foregroundColor(.secondary)

            if didSave {
                Label("Saved to leaderboard", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
            } else {
                VStack(spacing: 8) {
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                    Button("Save Score") {
                        saveScore()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 32)
            }

            HStack(spacing: 12) {
                Button("Play Again", action: onReplay)
                    .buttonStyle(.borderedProminent)
                Button("Leaderboard") {
                    showLeaderboard = true
                }
                .buttonStyle(.bordered)
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
            NavigationStack {
                LeaderboardView()
            }
        }
    }

    private func saveScore() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addEntry(name: trimmed, score: score)
        savedName = trimmed
        didSave = true
    }
}
