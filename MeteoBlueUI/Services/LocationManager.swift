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
    private let geocoder = CLGeocoder()
    @Published var location: CLLocation?
    @Published var city: MKMapItem?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    static func defaultMapItem() -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(
            latitude: 37.323,
            longitude: -122.032
        )
        let addressDict = [CNPostalAddressCityKey: "Cupertino"]
        let placemark = MKPlacemark(
            coordinate: coordinate,
            addressDictionary: addressDict
        )
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Cupertino"
        return mapItem
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            self.city = LocationManager.defaultMapItem()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else { return }
        self.location = location

        geocoder.reverseGeocodeLocation(location) {
            [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first,
                error == nil
            else { return }
            let mkPlacemark = MKPlacemark(placemark: placemark)
            self.city = MKMapItem(placemark: mkPlacemark)
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Failed to get location: \(error)")
    }
}
