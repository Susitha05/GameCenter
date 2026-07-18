import SwiftUI

/// Encodes the L1 -> L4 progression table from the Week 2 brief.
/// Everything plays out inside a single 60-second round; the level is derived
/// purely from elapsed time, so there's one source of truth for difficulty.
enum GameLevel: CaseIterable {
    case l1, l2, l3, l4

    /// Which level a round should be in, given seconds elapsed since round start.
    static func level(forElapsed elapsed: Double) -> GameLevel {
        switch elapsed {
        case ..<15:  return .l1
        case 15..<30: return .l2
        case 30..<45: return .l3
        default:      return .l4
        }
    }

    /// Total cards on the grid at this level.
    var cardCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        }
    }

    /// Columns for the LazyVGrid so the card count above renders as the shape
    /// described in the brief (row of 3 / 2x2 / 2x3 / 3x3).
    var gridColumns: Int {
        switch self {
        case .l1: return 3
        case .l2: return 2
        case .l3: return 3
        case .l4: return 3
        }
    }

    /// How long a lit card stays lit before it goes dark again.
    var litWindow: Double {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }

    /// L4 lights two cards at once instead of one.
    var simultaneousLitCount: Int {
        self == .l4 ? 2 : 1
    }

    var label: String {
        switch self {
        case .l1: return "L1"
        case .l2: return "L2"
        case .l3: return "L3"
        case .l4: return "L4"
        }
    }

    /// Distinct glow colour per level (submission checklist stretch goal).
    var color: Color {
        switch self {
        case .l1: return .green
        case .l2: return .blue
        case .l3: return .yellow
        case .l4: return .red
        }
    }
}
