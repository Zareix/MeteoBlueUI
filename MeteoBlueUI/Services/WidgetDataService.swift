//
//  WidgetDataService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 04/03/2026.
//

import CoreLocation
import Foundation
import MapKit
import OSLog
import WidgetKit

private let logger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "WidgetDataService")

// MARK: - Service

enum WidgetDataService {
    static let appGroupID = "group.com.raphaelgc.MeteoBlueUI"
    static let userDefaultsKey = "widget_forecast_data"
    static let staleThreshold: TimeInterval = 60 * 60 // 1 hour

    private static var provider: WeatherProviderService {
        switch WeatherProviderType.current {
        case .meteoblue: return MeteoBlueProviderService()
        case .weatherkit: return WeatherKitProviderService()
        }
    }

    static func isStale() -> Bool {
        guard let data = loadFromCache() else { return true }
        return Date().timeIntervalSince(data.savedAt) >= staleThreshold
    }

    static func loadFromCache() -> WidgetData? {
        let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
        guard let data = userDefaults.data(forKey: userDefaultsKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data)
        else {
            return nil
        }
        return widgetData
    }

    static func fetchWidgetData(for location: WeatherLocation) async throws -> WidgetData {
        let widgetData = try await provider.fetchWidgetData(location: location)

        if let encoded = try? JSONEncoder().encode(widgetData) {
            let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
            userDefaults.set(encoded, forKey: userDefaultsKey)
            WidgetCenter.shared.reloadAllTimelines()
        }

        return widgetData
    }

    static func fetchCurrentLocation() -> WeatherLocation {
        if let location = FavoriteCities().items.first {
            logger.info("⭐ Using location from favorites: \(location.city)")
            return location
        }

        if let location = SearchHistory().items.first {
            logger.info("📍 Using location from search history: \(location.city)")
            return location
        }

        logger.info("🏠 Using default location: Cupertino")
        return WeatherLocation(
            city: "Cupertino",
            country: "United States",
            latitude: 37.323,
            longitude: -122.032
        )
    }

    static func loadOrFetch() async -> WidgetData? {
        if !isStale(), let cached = loadFromCache() {
            return cached
        }

        let location = fetchCurrentLocation()

        do {
            return try await fetchWidgetData(for: location)
        } catch {
            logger.error("Failed to fetch widget data: \(error.localizedDescription)")
            return loadFromCache()
        }
    }
}
