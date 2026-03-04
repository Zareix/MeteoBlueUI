import Contacts

//
//  LocationService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var city: MKMapItem?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    static func defaultMapItem() -> MKMapItem {
        let location = CLLocation(latitude: 37.323, longitude: -122.032)
        let address = MKAddress(
            fullAddress: "Cupertino, United States",
            shortAddress: "United States"
        )
        let mapItem = MKMapItem(location: location, address: address)
        mapItem.name = "Cupertino"
        return mapItem
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            city = LocationManager.defaultMapItem()
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
                self.city = mapItem
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
