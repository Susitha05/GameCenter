import SwiftUI

struct SettingsTab: View {
    @ObservedObject private var notifications = NotificationService.shared
    @StateObject private var statsViewModel = StatsViewModel()

    @AppStorage("dailyChallengeEnabled") private var dailyChallengeEnabled = false
    @AppStorage("dailyChallengeHour") private var dailyChallengeHour = 9
    @AppStorage("dailyChallengeMinute") private var dailyChallengeMinute = 0

    @State private var showResetConfirmation = false

    private var challengeTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = dailyChallengeHour
                components.minute = dailyChallengeMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                dailyChallengeHour = components.hour ?? 9
                dailyChallengeMinute = components.minute ?? 0
                if dailyChallengeEnabled {
                    NotificationService.shared.scheduleDailyChallenge(at: newValue)
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Challenge") {
                    Toggle("Daily Reminder", isOn: Binding(
                        get: { dailyChallengeEnabled },
                        set: { newValue in
                            dailyChallengeEnabled = newValue
                            Task { await handleToggle(newValue) }
                        }
                    ))

                    if dailyChallengeEnabled {
                        DatePicker("Reminder Time", selection: challengeTime, displayedComponents: .hourAndMinute)

                        if !notifications.isAuthorized {
                            Text("Notifications aren't authorized yet. Enable them in system Settings for the reminder to appear.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Section("Data") {
                    Button("Reset All Stats", role: .destructive) {
                        showResetConfirmation = true
                    }
                }

                Section {
                    Text("Scores, personal bests, map pins, and the Quiz Rush leaderboard are all stored locally on this device.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .task {
                await notifications.refreshAuthorizationStatus()
            }
            .confirmationDialog(
                "Reset all stats?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetEverything()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears all recorded game sessions, personal bests, map pins, and the Quiz Rush leaderboard. This can't be undone.")
            }
        }
    }

    private func handleToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await NotificationService.shared.requestAuthorization()
            if granted {
                NotificationService.shared.scheduleDailyChallenge(at: challengeTime.wrappedValue)
            } else {
                dailyChallengeEnabled = false
            }
        } else {
            NotificationService.shared.cancelDailyChallenge()
        }
    }

    private func resetEverything() {
        statsViewModel.resetAllStats()
        LeaderboardStore.shared.clearAll()
        UserDefaults.standard.removeObject(forKey: "tapFrenzyHighScore")
        UserDefaults.standard.removeObject(forKey: "lightItUpHighScore")
        UserDefaults.standard.removeObject(forKey: "quizRushHighScore")
    }
}

#Preview {
    SettingsTab()
}
