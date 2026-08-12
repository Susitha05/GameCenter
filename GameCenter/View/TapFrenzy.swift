//
//  TapFrenzy.swift
//  GameCenter
//

import SwiftUI

// MARK: - Local storage for score history

/// One saved Tap Frenzy result — score + date, no name. A running log of
/// every round, separate from `highScore` (tracked via @AppStorage below).
    struct TapFrenzyScoreRecord: Codable, Identifiable {
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
     
    /// Persists Tap Frenzy score history to UserDefaults as JSON.
    enum TapFrenzyLocalStore {
        private static let key = "tapFrenzyScoreHistory"
     
        /// Appends a new record every time a round ends, tagging it with
        /// whatever location LocationService currently has (if any).
        @MainActor static func save(score: Int) {
            var history = load()
            let coordinate = LocationService.shared.coordinateForSession
            history.append(TapFrenzyScoreRecord(
                score: score,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude
            ))
            if let data = try? JSONEncoder().encode(history) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }

    static func load() -> [TapFrenzyScoreRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([TapFrenzyScoreRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - View

struct TapFrenzy: View {

    @State private var score = 0
    @State private var timeRemaining = 30

    @State private var xPos: CGFloat = 0
    @State private var yPos: CGFloat = 0

    @State private var gameStarted = false
    @State private var gameOver = false

    @State private var timer: Timer?

    @AppStorage("tapFrenzyHighScore") private var highScore = 0

    private var shareText: String {
        "I just scored \(score) on Tap Frenzy — beat that."
    }

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {


                if !gameStarted {
                    Spacer()

                    if highScore > 0 {
                        Text("Best: \(highScore)")
                            .font(.headline)
                            .foregroundStyle(.gray)
                            .padding(.bottom, 8)
                    }

                    Button {

                        startGame()

                    } label: {

                        Text("START GAME")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .padding()
                            .frame(width:220)
                            .background(.blue)
                            .clipShape(Capsule())

                    }

                }

                if gameStarted {

                    HStack {

                        HStack(spacing: 8) {

                            Text("🏹 Score :")

                            Text("\(score)")
                        }
                        .font(.system(size: 28).bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple,.blue],
                                startPoint: .leading,
                                endPoint: .trailing)
                        )

                        Spacer()

                        HStack(spacing: 20){
                            Text("⏳ :")

                            Text("\(timeRemaining)")
                        }
                        .font(.system(size: 28).bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple,.blue],
                                startPoint: .leading,
                                endPoint: .trailing)
                        )

                    }
                    .padding(.horizontal,20)
                   
                    Spacer()
                    Text("⚽️")
                        .font(.system(size: 120))
                        .offset(x: xPos, y: yPos)
                        .onTapGesture {

                            score += 1
                            moveTarget()

                        }

                }

                Spacer()

            }

            // MARK: Game Over

            if gameOver {

                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                VStack(spacing:20){

                    Text("🎉 Game Over")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Final Score")
                        .foregroundStyle(.white)

                    Text("\(score)")
                        .font(.system(size:60))
                        .foregroundStyle(.yellow)

                    Text("Best: \(highScore)")
                        .foregroundStyle(.gray)

                    Label("Saved to your local history", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)

                    HStack(spacing: 12) {

                        Button {

                            startGame()

                        } label: {

                            Text("Play Again")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .padding()
                                .frame(width:160)
                                .background(.green)
                                .clipShape(Capsule())

                        }

                        NavigationLink(destination: TapFrenzyHistoryView()) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .padding()
                                .frame(width:60)
                                .background(.white.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        ShareLink(item: shareText) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .padding()
                                .frame(width:60)
                                .background(.white.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                }

            }

        }
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: TapFrenzyHistoryView()) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.white)
                }
            }
        }

    }

    // MARK: Start Game

    func startGame() {

        score = 0
        timeRemaining = 30

        gameStarted = true
        gameOver = false

        moveTarget()

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in

            if timeRemaining > 0 {

                timeRemaining -= 1

            } else {

                timer?.invalidate()

                gameStarted = false
                gameOver = true

                endRound()

            }

        }

    }

    // MARK: End Round

    @MainActor func endRound() {

        if score > highScore {
            highScore = score
        }

        TapFrenzyLocalStore.save(score: score)
        
        // 1. Fetch the coordinate from your location service
        let coordinate = LocationService.shared.coordinateForSession
        
        // 2. Map it to the tuple expected by SessionStore (if it exists)
        let sessionCoordinate: (latitude: Double, longitude: Double)? = {
            guard let coord = coordinate else { return nil }
            return (latitude: coord.latitude, longitude: coord.longitude)
        }()
        
        // 3. Pass the coordinate into addSession
        SessionStore.shared.addSession(
            mode: .tapFrenzy,
            score: score,
            coordinate: sessionCoordinate
        )
    }

    // MARK: Move Target

    func moveTarget() {

        xPos = CGFloat.random(in: -140...140)
        yPos = CGFloat.random(in: -250...250)

    }

}

#Preview {
    NavigationStack { TapFrenzy() }
}
