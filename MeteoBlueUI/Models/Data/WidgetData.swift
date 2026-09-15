//
//  WidgetData.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 19/05/2026.
//

import Foundation

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
    // Max/min du jour courant, pour le widget rectangulaire de l'écran verrouillé.
    // Optionnels : les caches écrits avant l'ajout ne les contiennent pas.
    var dailyTemperatureMax: Double?
    var dailyTemperatureMin: Double?
    let savedAt: Date

    init(
        location: WeatherLocation,
        hours: [WidgetHourEntry],
        dailyTemperatureMax: Double? = nil,
        dailyTemperatureMin: Double? = nil,
        savedAt: Date
    ) {
        self.location = location
        self.hours = hours
        self.dailyTemperatureMax = dailyTemperatureMax
        self.dailyTemperatureMin = dailyTemperatureMin
        self.savedAt = savedAt
    }
}
