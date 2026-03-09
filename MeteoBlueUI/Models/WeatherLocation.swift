//
//  WeatherLocation.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 04/03/2026.
//

import Foundation
import MapKit

struct WeatherLocation: Equatable, Hashable, Codable, Identifiable {
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    var id: String {
        city + country + String(latitude) + String(longitude)
    }

    init(city: String, country: String, latitude: Double, longitude: Double) {
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from mapItem: MKMapItem) {
        let address = mapItem.addressRepresentations
        self.city = mapItem.addressRepresentations?.cityName
            ?? mapItem.name
            ?? "Unknown"
        self.country = address?.regionName ?? ""
        self.latitude = mapItem.location.coordinate.latitude
        self.longitude = mapItem.location.coordinate.longitude
    }

    static func == (lhs: WeatherLocation, rhs: WeatherLocation) -> Bool {
        return lhs.id == rhs.id
    }
}
