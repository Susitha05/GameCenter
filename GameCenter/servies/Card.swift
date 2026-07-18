import Foundation

/// A single grid tile in Light It Up.
/// Identifiable so it can be driven straight off a @State/@Published array in a ForEach.
struct Card: Identifiable, Equatable {
    let id: Int
    var isLit: Bool = false
}
