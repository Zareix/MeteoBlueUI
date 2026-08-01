//
//  WidgetDataService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 04/03/2026.
//

import Foundation
import WidgetKit

// MARK: - Service

enum WidgetDataService {
    static let appGroupID = "group.com.raphaelgc.MeteoBlueUI"
    static let staleThreshold: TimeInterval = 60 * 60 // 1 hour

    // Cache is keyed per provider so widget instances configured with different providers don't
    // overwrite each other's data.
    private static func userDefaultsKey(for providerType: WeatherProviderType) -> String {
        "widget_forecast_data_\(providerType.rawValue)"
    }

    static func isStale(providerType: WeatherProviderType) -> Bool {
        guard let data = loadFromCache(providerType: providerType) else { return true }
        return Date().timeIntervalSince(data.savedAt) >= staleThreshold
    }

    static func loadFromCache(providerType: WeatherProviderType) -> WidgetData? {
        let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
        guard let data = userDefaults.data(forKey: userDefaultsKey(for: providerType)),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data)
        else {
            return nil
        }
        return widgetData
    }

    static func fetchWidgetData(for location: WeatherLocation, providerType: WeatherProviderType) async throws -> WidgetData {
        let widgetData = try await providerType.makeService().fetchWidgetData(location: location)

        if let encoded = try? JSONEncoder().encode(widgetData) {
            let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
            userDefaults.set(encoded, forKey: userDefaultsKey(for: providerType))
            WidgetCenter.shared.reloadAllTimelines()
        }

        return widgetData
    }

    static func fetchCurrentLocation() -> WeatherLocation {
        if let location = FavoriteCities().items.first {
            return location
        }

        if let location = SearchHistory().items.first {
            return location
        }

        return WeatherLocation(
            city: "Cupertino",
            country: "United States",
            latitude: 37.323,
            longitude: -122.032
        )
    }
}
