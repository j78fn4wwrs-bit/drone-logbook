import Foundation
import CoreLocation

/// One-shot "when in use" location for the flight form. Nothing is stored except
/// what the user saves on the flight.
final class LocationFetcher: NSObject, ObservableObject, CLLocationManagerDelegate {
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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            guard self.isLocating else { return }
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            } else if status != .notDetermined {
                self.isLocating = false
                self.failed = true
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coord = locations.last?.coordinate
        DispatchQueue.main.async {
            self.coordinate = coord
            self.isLocating = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLocating = false
            self.failed = true
        }
    }
}

extension CLLocationCoordinate2D {
    var shortString: String {
        String(format: "%.4f, %.4f", latitude, longitude)
    }
}
