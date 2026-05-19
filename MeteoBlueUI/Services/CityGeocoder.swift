//
//  CityGeocoder.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 19/05/2026.
//

import Foundation
import MapKit

enum CityGeocoder {
    static func resolve(title: String, subtitle: String) async throws -> WeatherLocation? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(title), \(subtitle)"
        let search = MKLocalSearch(request: request)
        let response = try? await search.start()
        guard let mapItem = response?.mapItems.first else {
            return nil
        }
        return WeatherLocation(from: mapItem)
    }
}
