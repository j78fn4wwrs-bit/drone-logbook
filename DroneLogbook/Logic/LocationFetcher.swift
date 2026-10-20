import Foundation
import Combine
@preconcurrency import CoreLocation

/// One-shot "when in use" location for the flight form. Nothing is stored except
/// what the user saves on the flight.
///
/// The manager is created on the main actor, so Core Location delivers delegate
/// callbacks on the main thread. The delegate methods stay nonisolated and hop
/// back with already-copied Sendable values, which keeps CLLocationManager off
/// any @Sendable closure.
@MainActor
final class LocationFetcher: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var isLocating = false
    @Published var failed = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        failed = false
        switch manager.authorizationStatus {
        case .notDetermined:
            isLocating = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isLocating = true
            manager.requestLocation()
        default:
            failed = true
        }
    }

    fileprivate func applyAuthorization(_ status: CLAuthorizationStatus) {
        guard isLocating else { return }
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status != .notDetermined {
            isLocating = false
            failed = true
        }
    }

    fileprivate func applyFix(latitude: Double?, longitude: Double?) {
        if let latitude, let longitude {
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            isLocating = false
        } else {
            applyFailure()
        }
    }

    fileprivate func applyFailure() {
        isLocating = false
        failed = true
    }
}

extension LocationFetcher: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.applyAuthorization(status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latitude = locations.last?.coordinate.latitude
        let longitude = locations.last?.coordinate.longitude
        Task { @MainActor in
            self.applyFix(latitude: latitude, longitude: longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.applyFailure()
        }
    }
}

extension CLLocationCoordinate2D {
    var shortString: String {
        String(format: "%.4f, %.4f", latitude, longitude)
    }
}
