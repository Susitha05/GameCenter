//
//  LightUp.swift
//  GameCenter
//
//  Created by TUTU on 17/07/2026.
//

import SwiftUI

// MARK: - Local storage for score history

/// One saved Light It Up result — just enough to keep a local history and
/// share it. Not the same thing as `engine.highScore` (that's still tracked
/// separately via @AppStorage); this is a running log of every round.
struct LightItUpScoreRecord: Codable, Identifiable {
    let id: UUID
    let score: Int
    let date: Date
    let latitude: Double?
    let longitude: Double?
 
    init(score: Int, date: Date = Date(), latitude: Double? = nil, longitude: Double? = nil) {
        self.id = UUID()
        self.score = score
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
    }
}
 
/// Persists Light It Up score history to UserDefaults as JSON.
enum LightItUpLocalStore {
    private static let key = "lightItUpScoreHistory"
 
    /// Appends a new record every time a round ends, tagging it with
    /// whatever location LocationService currently has (if any).
    @MainActor static func save(score: Int) {
        var history = load()
        let coordinate = LocationService.shared.coordinateForSession
        history.append(LightItUpScoreRecord(
            score: score,
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude
        ))
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> [LightItUpScoreRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([LightItUpScoreRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - View

struct LightUp: View {
    @StateObject private var engine = LightItUpEngine()
    @State private var didSaveThisRound = false

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: engine.level.gridColumns
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                Spacer()
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(engine.cards) { card in
                        CardTile(card: card, glowColor: engine.level.color)
                            .onTapGesture {
                                engine.tapCard(card)
                            }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 12)

            if engine.showLevelUpFlash {
                engine.level.color
                    .opacity(0.22)
                    .ignoresSafeArea()
            }

            if engine.isGameOver {
                GameOverCard(
                    score: engine.score,
                    highScore: engine.highScore,
                    onReplay: {
                        didSaveThisRound = false
                        engine.startRound()
                    }
                )
            }
        }
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: LightUpHistoryView()) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .onAppear {
            if !engine.isRunning && !engine.isGameOver {
                engine.startRound()
            }
        }
        .onDisappear {
            engine.stopRound()
        }
        .onChange(of: engine.isGameOver) { isOver in
            // Save exactly once per finished round, not on every re-render.
            if isOver && !didSaveThisRound {
                LightItUpLocalStore.save(score: engine.score)
                didSaveThisRound = true
                let coordinate = LocationService.shared.coordinateForSession
                
                // 2. Map it to the tuple expected by SessionStore (if it exists)
                let sessionCoordinate: (latitude: Double, longitude: Double)? = {
                    guard let coord = coordinate else { return nil }
                    return (latitude: coord.latitude, longitude: coord.longitude)
                }()
                
                
                SessionStore.shared.addSession(
                    mode: .lightItUp,
                    score: engine.score,
                    coordinate: sessionCoordinate
                )
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Score: \(engine.score)")
                    .font(.system(size: 24))
                    .foregroundStyle(.gray)
                    .fontWeight(.bold)
                Text("Best: \(engine.highScore)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(engine.level.label)
                    .font(.headline)
                    .foregroundColor(engine.level.color)
                Text(String(format: "%.1fs", max(engine.timeRemaining, 0)))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }
}

private struct CardTile: View {
    let card: Card
    let glowColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(card.isLit ? glowColor : Color(.secondarySystemBackground))
            .frame(height: 90)
            .scaleEffect(card.isLit ? 1.05 : 1.0)
            .shadow(color: card.isLit ? glowColor.opacity(0.7) : .clear,
                    radius: card.isLit ? 14 : 0)
            .animation(.easeInOut(duration: 0.2), value: card.isLit)
    }
}

private struct GameOverCard: View {
    let score: Int
    let highScore: Int
    let onReplay: () -> Void

    private var shareText: String {
        "I just scored \(score) on Light It Up — beat that."
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Round Over")
                .font(.largeTitle.bold())
            Text("Score: \(score)")
                .font(.title2)
            Text("Best: \(highScore)")
                .foregroundColor(.secondary)

            Label("Saved to your local history", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.subheadline)

            HStack(spacing: 12) {
                Button("Play Again", action: onReplay)
                    .buttonStyle(.borderedProminent)

                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)

                NavigationLink(destination: LightUpHistoryView()) {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .background(.thinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

#Preview {
    LightUp()
}
