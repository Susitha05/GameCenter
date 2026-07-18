import SwiftUI
import Combine

/// Drives a single 60-second Light It Up round: level progression, the
/// light-up/tap-down cycle, scoring, and persisted high score.
@MainActor
final class LightItUpEngine: ObservableObject {

    @Published var cards: [Card] = []
    @Published var level: GameLevel = .l1
    @Published var score: Int = 0
    @Published var timeRemaining: Double = Self.roundLength
    @Published var isRunning: Bool = false
    @Published var isGameOver: Bool = false
    @Published var showLevelUpFlash: Bool = false

    @AppStorage("lightItUpHighScore") var highScore: Int = 0

    static let roundLength: Double = 60
    private let tickInterval: Double = 0.1
    private let missedTapPenalty = 5
    private let wrongTapPenalty = 5
    private let correctTapReward = 10

    private var roundTimer: Timer?
    private var lightTimer: Timer?
    private var currentlyLitIDs: Set<Int> = []

    func startRound() {
        roundTimer?.invalidate()
        lightTimer?.invalidate()

        score = 0
        timeRemaining = Self.roundLength
        isGameOver = false
        isRunning = true
        level = .l1
        setupCards(for: .l1)

        roundTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickRound() }
        }
        restartLightTimer()
    }

    func stopRound() {
        isRunning = false
        roundTimer?.invalidate()
        lightTimer?.invalidate()
    }

    /// Called when the player taps a specific card.
    func tapCard(_ card: Card) {
        guard isRunning, let idx = cards.firstIndex(where: { $0.id == card.id }) else { return }

        withAnimation(.easeOut(duration: 0.15)) {
            if cards[idx].isLit {
                score += correctTapReward
                cards[idx].isLit = false
                currentlyLitIDs.remove(card.id)
            } else {
                score = max(0, score - wrongTapPenalty)
            }
        }
    }

    // MARK: - Private

    private func setupCards(for level: GameLevel) {
        cards = (0..<level.cardCount).map { Card(id: $0) }
        currentlyLitIDs = []
    }

    private func tickRound() {
        guard isRunning else { return }

        timeRemaining -= tickInterval
        let elapsed = Self.roundLength - timeRemaining
        let newLevel = GameLevel.level(forElapsed: elapsed)

        if newLevel.label != level.label {
            level = newLevel
            setupCards(for: newLevel)
            restartLightTimer()
            flashLevelUp()
        }

        if timeRemaining <= 0 {
            endRound()
        }
    }

    private func flashLevelUp() {
        showLevelUpFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.showLevelUpFlash = false
        }
    }

    private func restartLightTimer() {
        lightTimer?.invalidate()
        lightTimer = Timer.scheduledTimer(withTimeInterval: level.litWindow, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.cycleLights() }
        }
        cycleLights()
    }

    /// Dims whatever was lit (penalising missed taps), then lights a fresh
    /// random selection of cards for the current level.
    private func cycleLights() {
        guard isRunning, !cards.isEmpty else { return }

        if !currentlyLitIDs.isEmpty {
            score = max(0, score - missedTapPenalty * currentlyLitIDs.count)
        }

        for i in cards.indices { cards[i].isLit = false }
        currentlyLitIDs = []

        let howMany = min(level.simultaneousLitCount, cards.count)
        let chosenIndices = cards.indices.shuffled().prefix(howMany)
        for i in chosenIndices {
            cards[i].isLit = true
            currentlyLitIDs.insert(cards[i].id)
        }
    }

    private func endRound() {
        isRunning = false
        roundTimer?.invalidate()
        lightTimer?.invalidate()
        isGameOver = true
        if score > highScore {
            highScore = score
        }
    }
}
