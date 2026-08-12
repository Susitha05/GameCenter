import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {

    static let shared = LocationService()

    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override private init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10

        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {

        print("📍 Requesting location permission")

        switch manager.authorizationStatus {

        case .notDetermined:

            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse,
             .authorizedAlways:

            print("📍 Location permission already granted")
            manager.startUpdatingLocation()

        case .denied:

            print("❌ Location permission denied")

        case .restricted:

            print("❌ Location permission restricted")

        @unknown default:

            break
        }
    }

    var coordinateForSession:
        (latitude: Double, longitude: Double)? {

        guard let coordinate = currentCoordinate else {
            print("❌ No current location available")
            return nil
        }

        print(
            "📍 Saving location:",
            coordinate.latitude,
            coordinate.longitude
        )

        return (
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}


// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        let status = manager.authorizationStatus

        Task { @MainActor in

            self.authorizationStatus = status

            print("📍 Authorization changed:", status.rawValue)

            if status == .authorizedWhenInUse ||
               status == .authorizedAlways {

                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let latest = locations.last else {
            return
        }

        print(
            "📍 GPS:",
            latest.coordinate.latitude,
            latest.coordinate.longitude
        )

        Task { @MainActor in

            self.currentCoordinate = latest.coordinate
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        print(
            "❌ Location error:",
            error.localizedDescription
        )
    }
}
