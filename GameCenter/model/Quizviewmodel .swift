import SwiftUI

/// View-state for Quiz Rush. The view switches on this rather than juggling
/// separate booleans for loading/error/content.
enum QuizState: Equatable {
    case loading
    case loaded
    case failed(String)
}

/// All Quiz Rush game logic lives here — fetching, scoring, streaks, and
/// advancing through the round — so the view stays a thin, dumb renderer of
/// whatever state this object is in.
@MainActor
final class QuizViewModel: ObservableObject {

    @Published private(set) var state: QuizState = .loading
    @Published private(set) var questions: [Question] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var shuffledAnswers: [String] = []
    @Published private(set) var score: Int = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var isAnswering: Bool = false
    @Published private(set) var lastAnswerWasCorrect: Bool?
    @Published private(set) var isRoundComplete: Bool = false

    @AppStorage("quizRushHighScore") var highScore: Int = 0

    private let service: TriviaService
    private let correctReward = 10
    private let wrongPenalty = 3
    private let streakBonusPerExtraCorrect = 2
    private let answerPauseNanoseconds: UInt64 = 500_000_000

    init(service: TriviaService = TriviaService()) {
        self.service = service
    }

    var currentQuestion: Question? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var totalQuestions: Int { questions.count }

    /// Fetches a fresh set of 10 questions and resets round state. Called
    /// from `.task` on appear, and again from the Retry / Play Again buttons.
    func load() async {
        state = .loading
        isRoundComplete = false
        currentIndex = 0
        score = 0
        streak = 0
        lastAnswerWasCorrect = nil
        isAnswering = false

        do {
            let fetched = try await service.fetchQuestions()
            guard !fetched.isEmpty else {
                state = .failed("No questions came back. Please try again.")
                return
            }
            questions = fetched
            prepareAnswers()
            state = .loaded
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't load questions. Check your connection and retry."
            state = .failed(message)
        }
    }

    /// Called when the player taps an answer button.
    func selectAnswer(_ answer: String) {
        guard let question = currentQuestion, !isAnswering else { return }

        isAnswering = true
        let isCorrect = answer == question.correctAnswer
        lastAnswerWasCorrect = isCorrect

        if isCorrect {
            streak += 1
            score += correctReward + (streak - 1) * streakBonusPerExtraCorrect
        } else {
            streak = 0
            score = max(0, score - wrongPenalty)
        }

        Task {
            try? await Task.sleep(nanoseconds: answerPauseNanoseconds)
            advance()
        }
    }

    private func advance() {
        lastAnswerWasCorrect = nil
        isAnswering = false

        if currentIndex + 1 < questions.count {
            currentIndex += 1
            prepareAnswers()
        } else {
            isRoundComplete = true
            if score > highScore {
                highScore = score
            }
        }
    }

    private func prepareAnswers() {
        shuffledAnswers = currentQuestion?.shuffledAnswers ?? []
    }
}
