//
//  MeteoBlueAPIService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import Foundation
import MapKit

struct MeteoBlueAPIService {
    func getCityFromCompletion(title: String, subtitle : String) async throws -> MKMapItem? {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "\(title), \(subtitle)"
        let search = MKLocalSearch(request: searchRequest)
        let response =  try? await search.start()
        guard let mapItem = response?.mapItems.first else {
            print("No results found")
            return nil
        }
        return mapItem
    }
    
    func fetchForecast(
        city: MKMapItem
    ) async throws -> MeteoBlueAPIForecast {
        let (lat, lon) = (
            city.placemark.coordinate.latitude,
            city.placemark.coordinate.longitude
        )
        print(
            "Fetching Meteo Blue API  for forecast of \(city.placemark.locality ?? "Unknown") : lat: \(lat), lon: \(lon)"
        )
        let token = KeychainService().getMetoBlueAPIToken()
        if token == nil {
            throw AppError.runtimeError("No API token found")
        }
        guard
            let url = URL(
                string:
                    "https://my.meteoblue.com/packages/basic-1h_basic-day?lat=\(lat)&lon=\(lon)&apikey=\(token ?? "")"
            )
        else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MeteoBlueAPIForecast.self, from: data)
    }
}
