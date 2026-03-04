import Contacts
import CoreLocation
import MapKit

//
//  LocationService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
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
