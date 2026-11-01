import Contacts
import CoreLocation
import MapKit

///
///  LocationService.swift
///  MeteoBlueUI
///
///  Created by Raphaël Catarino on 13/05/2025.
///
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var currentLocation: WeatherLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    static func defaultLocation() -> WeatherLocation {
        return WeatherLocation(
            city: "Cupertino",
            country: "United States",
            latitude: 37.323,
            longitude: -122.032
        )
    }

    /// Même seuil que le chemin rapide du widget : au-delà, on redemande un fix GPS.
    private static let cachedLocationMaxAge: TimeInterval = 15 * 60

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Chemin rapide : la dernière position connue du système est quasi
            // instantanée à lire, alors qu'un requestLocation() peut mettre plusieurs
            // secondes à donner un fix (l'app principale n'a pas le budget serré du
            // widget, mais autant faire pareil).
            if let last = manager.location,
               Date().timeIntervalSince(last.timestamp) < Self.cachedLocationMaxAge {
                self.location = last
                reverseGeocode(last)
            } else {
                manager.requestLocation()
            }
        default:
            currentLocation = LocationManager.defaultLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else { return }
        self.location = location
        reverseGeocode(location)
    }

    private func reverseGeocode(_ location: CLLocation) {
        let request = MKReverseGeocodingRequest(location: location)
        request?.getMapItems(completionHandler: { [weak self] mapItems, error in
            guard let self, let mapItem = mapItems?.first, error == nil else { return }
            DispatchQueue.main.async {
                self.currentLocation = WeatherLocation(from: mapItem)
            }
        })
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Failed to get location: \(error)")
    }
}
