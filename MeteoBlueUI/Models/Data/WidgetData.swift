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
    let savedAt: Date
}
