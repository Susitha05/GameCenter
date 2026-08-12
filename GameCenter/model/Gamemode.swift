import SwiftUI

/// Identifies which of the three games a session or high score belongs to.
enum GameMode: String, Codable, CaseIterable, Identifiable {
    case tapFrenzy = "Tap Frenzy"
    case lightItUp = "Light It Up"
    case quizRush = "Quiz Rush"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tapFrenzy: return "hand.tap.fill"
        case .lightItUp: return "square.grid.3x3.fill"
        case .quizRush: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .tapFrenzy: return .yellow
        case .lightItUp: return .blue
        case .quizRush: return .orange
        }
    }
}
