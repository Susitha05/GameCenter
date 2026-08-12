import Foundation

enum TriviaServiceError: LocalizedError {
    case badURL
    case badResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Couldn't build the request URL."
        case .badResponse:
            return "The server didn't respond as expected."
        case .decodingFailed:
            return "Couldn't understand the response from the trivia service."
        }
    }
}

/// One job: fetch 10 multiple-choice questions from Open Trivia DB.
/// The URL lives in exactly one place, per the brief.
struct TriviaService {
    private let endpoint = "https://opentdb.com/api.php?amount=10&type=multiple"

    func fetchQuestions() async throws -> [Question] {
        guard let url = URL(string: endpoint) else {
            throw TriviaServiceError.badURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw TriviaServiceError.badResponse
        }

        do {
            let decoded = try JSONDecoder().decode(TriviaResponse.self, from: data)
            return decoded.results
        } catch {
            throw TriviaServiceError.decodingFailed
        }
    }
}
