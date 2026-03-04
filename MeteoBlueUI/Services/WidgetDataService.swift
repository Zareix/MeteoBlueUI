//
//  WidgetDataService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 04/03/2026.
//

import Foundation
import WidgetKit

// MARK: - Shared model (Codable so it can be stored in UserDefaults)

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
    static let appGroupID = "group.com.zareix.MeteoBlueUI"
    static let userDefaultsKey = "widget_forecast_data"

    /// Save the next 6 upcoming hours for the given city into the shared App Group UserDefaults.
    static func save(location: WeatherLocation, hours: [MeteoData1H]) {
        let upcoming = hours
            .filter { $0.time >= Date() }
            .map {
                WidgetHourEntry(
                    time: $0.time,
                    symbol: $0.symbol,
                    description: $0.description,
                    temperature: $0.temperature,
                    precipitationProbability: $0.precipitationProbability
                )
            }

        let widgetData = WidgetData(
            location: location,
            hours: Array(upcoming),
            savedAt: Date()
        )

        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let encoded = try? JSONEncoder().encode(widgetData)
        else { return }

        defaults.set(encoded, forKey: userDefaultsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Load the cached widget data from the shared App Group UserDefaults.
    static func load() -> WidgetData? {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: userDefaultsKey),
            let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return nil }
        return widgetData
    }
}
