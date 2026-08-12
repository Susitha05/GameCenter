import Foundation

/// Top-level shape of https://opentdb.com/api.php?amount=10&type=multiple
struct TriviaResponse: Decodable {
    let results: [Question]
}

/// A single trivia question. HTML entities in the raw API strings (e.g. `&quot;`,
/// `&#039;`) are decoded once here, at parse time, so every other layer of the
/// app (ViewModel, view, answer comparison) can just work with plain text.
struct Question: Identifiable {
    let id = UUID()
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    /// Correct answer + incorrect answers, combined and shuffled — used to
    /// build the 4 answer buttons.
    var shuffledAnswers: [String] {
        ([correctAnswer] + incorrectAnswers).shuffled()
    }
}

extension Question: Decodable {
    private enum CodingKeys: String, CodingKey {
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawQuestion = try container.decode(String.self, forKey: .question)
        let rawCorrect = try container.decode(String.self, forKey: .correctAnswer)
        let rawIncorrect = try container.decode([String].self, forKey: .incorrectAnswers)

        question = rawQuestion.htmlDecoded
        correctAnswer = rawCorrect.htmlDecoded
        incorrectAnswers = rawIncorrect.map { $0.htmlDecoded }
    }
}

extension String {
    /// Open Trivia DB returns HTML-entity-encoded text by default
    /// (e.g. "Who invented the World Wide Web?" comes back with `&amp;`,
    /// `&quot;`, `&#039;` etc.). This decodes it back to plain text.
    var htmlDecoded: String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributed.string
    }
}
