//
//  TapFrenzyHistoryView.swift
//  GameCenter
//

import SwiftUI

struct TapFrenzyHistoryView: View {
    @State private var records: [TapFrenzyScoreRecord] = []
    @State private var showClearConfirmation = false

    private var sortedRecords: [TapFrenzyScoreRecord] {
        records.sorted { $0.date > $1.date }
    }

    private var bestScore: Int {
        records.map(\.score).max() ?? 0
    }

    private var averageScore: Int {
        guard !records.isEmpty else { return 0 }
        return records.map(\.score).reduce(0, +) / records.count
    }

    var body: some View {
        List {
            if !records.isEmpty {
                Section {
                    HStack {
                        StatColumn(value: "\(records.count)", label: "Rounds")
                        Spacer()
                        StatColumn(value: "\(bestScore)", label: "Best")
                        Spacer()
                        StatColumn(value: "\(averageScore)", label: "Average")
                    }
                    .padding(.vertical, 4)
                }
            }

            if sortedRecords.isEmpty {
                emptyState
            } else {
                Section("All Rounds") {
                    ForEach(sortedRecords) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(record.score) points")
                                    .font(.body.weight(.medium))
                                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if record.score == bestScore {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Score History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !records.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear", role: .destructive) {
                        showClearConfirmation = true
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear all saved scores?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                TapFrenzyLocalStore.clear()
                records = []
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every saved Tap Frenzy score. This can't be undone.")
        }
        .onAppear {
            records = TapFrenzyLocalStore.load()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No scores yet")
                .font(.headline)
            Text("Play a round of Tap Frenzy to see it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
    }
}

private struct StatColumn: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack { TapFrenzyHistoryView() }
}
