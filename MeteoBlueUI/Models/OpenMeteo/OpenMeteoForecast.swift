//
//  OpenMeteoForecast.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 31/07/2026.
//

import Foundation

// MARK: - OpenMeteoForecast

struct OpenMeteoForecast: Codable {
    let hourly: OpenMeteoHourly
    let daily: OpenMeteoDaily
    // Only present when minutely_15 variables are requested.
    let minutely15: OpenMeteoMinutely15?

    enum CodingKeys: String, CodingKey {
        case hourly, daily
        case minutely15 = "minutely_15"
    }
}

// MARK: - OpenMeteoMinutely15

struct OpenMeteoMinutely15: Codable {
    let time: [String]
    let precipitation: [Double?]?
}

// MARK: - OpenMeteoHourlyForecast

struct OpenMeteoHourlyForecast: Codable {
    let hourly: OpenMeteoHourly
}

// MARK: - OpenMeteoWidgetForecast

/// Réponse allégée du widget : heures + températures min/max du jour.
struct OpenMeteoWidgetForecast: Codable {
    let hourly: OpenMeteoHourly
    let daily: OpenMeteoWidgetDaily
}

// MARK: - OpenMeteoWidgetDaily

struct OpenMeteoWidgetDaily: Codable {
    let time: [String]
    let temperature2MMax: [Double?]
    let temperature2MMin: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2MMax = "temperature_2m_max"
        case temperature2MMin = "temperature_2m_min"
    }
}

// MARK: - OpenMeteoHourly

struct OpenMeteoHourly: Codable {
    let time: [String]
    // Some fields can be null depending on which underlying model Open-Meteo selects for a point.
    let temperature2M: [Double?]
    // Absent entirely from the widget's slimmer request (fetchWidgetData doesn't ask for these).
    let apparentTemperature: [Double?]?
    let precipitation: [Double?]?
    let precipitationProbability: [Int?]
    let weathercode: [Int?]
    let isDay: [Int?]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2M = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitation
        case precipitationProbability = "precipitation_probability"
        case weathercode
        case isDay = "is_day"
    }
}

// MARK: - OpenMeteoDaily

struct OpenMeteoDaily: Codable {
    let time: [String]
    let weathercode: [Int?]
    let temperature2MMax: [Double?]
    let temperature2MMin: [Double?]
    let precipitationSum: [Double?]
    let precipitationProbabilityMax: [Int?]
    let sunrise: [String]
    let sunset: [String]

    enum CodingKeys: String, CodingKey {
        case time, weathercode
        case temperature2MMax = "temperature_2m_max"
        case temperature2MMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case sunrise, sunset
    }
}
