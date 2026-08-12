import SwiftUI

/// Small reusable pill showing a labeled score value in a given colour.
struct ScoreBadge: View {
    let label: String
    let value: Int
    var color: Color = .accentColor

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(color.opacity(0.12))
        .cornerRadius(14)
    }
}

#Preview {
    ScoreBadge(label: "Score", value: 120, color: .blue)
}
