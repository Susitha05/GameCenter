import SwiftUI
import MapKit

struct MapTab: View {
    @ObservedObject private var sessionStore = SessionStore.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
    )
    @State private var selectedSession: GameSession?
    @State private var hasCenteredOnce = false

    private var pinnedSessions: [GameSession] {
        sessionStore.sessions.filter { $0.hasLocation }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pinnedSessions.isEmpty {
                    emptyState
                } else {
                    Map(coordinateRegion: $region, annotationItems: pinnedSessions) { session in
                        MapAnnotation(coordinate: session.coordinate) {
                            Button {
                                selectedSession = session
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: session.mode.icon)
                                        .font(.caption)
                                        .padding(6)
                                        .background(session.mode.color)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                    Text("\(session.score)")
                                        .font(.caption2.bold())
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Map")
            .onAppear {
                LocationService.shared.requestPermission()
                centerOnLatestSessionIfNeeded()
            }
            .sheet(item: $selectedSession) { session in
                sessionDetail(session)
            }
        }
    }

    private func centerOnLatestSessionIfNeeded() {
        guard !hasCenteredOnce,
              let latest = pinnedSessions.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            return
        }
        hasCenteredOnce = true
        region = MKCoordinateRegion(
            center: latest.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No sessions with a location yet")
                .font(.headline)
            Text("Play a round with location access enabled to see it pinned here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func sessionDetail(_ session: GameSession) -> some View {
        VStack(spacing: 12) {
            Image(systemName: session.mode.icon)
                .font(.largeTitle)
                .foregroundColor(session.mode.color)
            Text(session.mode.rawValue)
                .font(.title2.bold())
            ScoreBadge(label: "Score", value: session.score, color: session.mode.color)
            Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .presentationDetents([.height(280)])
    }
}

private extension GameSession {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }
}

#Preview {
    MapTab()
}
