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

private let wdLogger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "WidgetDataService")

// MARK: - Shared models

struct WidgetHourEntry: Codable {
    let time: Date
    let symbol: String
    let description: String
    let temperature: Double
    let precipitationProbability: Int
}

struct WidgetData: Codable {
    let location: WeatherLocation
    let hours: [WidgetHourEntry]
    let savedAt: Date
}

// MARK: - Service

enum WidgetDataService {
    static let appGroupID = "group.com.raphaelgc.MeteoBlueUI"
    static let userDefaultsKey = "widget_forecast_data"
    static let staleThreshold: TimeInterval = 60 * 60 // 1 hour

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
        guard let token = KeychainService().getMetoBlueAPIToken() else {
            throw AppError.noAPIToken
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "my.meteoblue.com"
        components.path = "/packages/basic-1h_basic-day"
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.latitude)),
            URLQueryItem(name: "lon", value: String(location.longitude)),
            URLQueryItem(name: "apikey", value: token),
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200 ... 299: break
            case 401: throw AppError.invalidAPIToken
            case 429: throw AppError.rateLimitExceeded
            default: throw AppError.httpError(http.statusCode)
            }
        }

        let forecast = try JSONDecoder().decode(MeteoBlueAPIForecast.self, from: data)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let now = Date().addingTimeInterval(-3600)

        let hours: [WidgetHourEntry] = forecast.data1H.time.enumerated().compactMap { index, timeStr in
            let date = formatter.date(from: timeStr) ?? Date()
            guard date >= now else { return nil }
            return WidgetHourEntry(
                time: date,
                symbol: PictoMapper.pictoToSFSymbol(
                    picto: forecast.data1H.pictocode[index],
                    isDaylight: forecast.data1H.isdaylight[index] != 0
                ),
                description: PictoMapper.pictoToDescription(picto: forecast.data1H.pictocode[index]),
                temperature: forecast.data1H.temperature[index],
                precipitationProbability: forecast.data1H.precipitationProbability[index]
            )
        }

        let widgetData = WidgetData(location: location, hours: hours, savedAt: Date())

        if let encoded = try? JSONEncoder().encode(widgetData) {
            let userDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
            userDefaults.set(encoded, forKey: userDefaultsKey)
        }

        return widgetData
    }

    static func fetchCurrentLocation() -> WeatherLocation {
        if let location = SearchHistory().items.first {
            wdLogger.info("📍 Using location from search history: \(location.city)")
            return location
        }

        if let location = FavoriteCities().items.first {
            wdLogger.info("⭐ Using location from favorites: \(location.city)")
            return location
        }

        wdLogger.info("🏠 Using default location: Cupertino")
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
            wdLogger.error("Failed to fetch widget data: \(error.localizedDescription)")
            return loadFromCache()
        }
    }
}
