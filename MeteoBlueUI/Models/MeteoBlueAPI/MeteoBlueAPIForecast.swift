//
//  MeteoBlueAPIForecast.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 11/05/2025.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let meteoBlueAPICurrentData = try? JSONDecoder().decode(MeteoBlueAPICurrentData.self, from: jsonData)

import Foundation

// MARK: - MeteoBlueAPIForecast
struct MeteoBlueAPIForecast: Codable {
    let metadata: Metadata
    let units: Units
    let data1H: Data1H
    let dataDay: DataDay

    enum CodingKeys: String, CodingKey {
        case metadata, units
        case data1H = "data_1h"
        case dataDay = "data_day"
    }
}

// MARK: - Data1H
struct Data1H: Codable {
    let time: [String]
    let snowfraction: [Int]
    let windspeed, temperature: [Double]
    let precipitationProbability: [Int]
    let convectivePrecipitation: [Double]
    let rainspot: [String]
    let pictocode: [Int]
    let felttemperature, precipitation: [Double]
    let isdaylight, uvindex, relativehumidity: [Int]
    let sealevelpressure: [Double]
    let winddirection: [Int]

    enum CodingKeys: String, CodingKey {
        case time, snowfraction, windspeed, temperature
        case precipitationProbability = "precipitation_probability"
        case convectivePrecipitation = "convective_precipitation"
        case rainspot, pictocode, felttemperature, precipitation, isdaylight, uvindex, relativehumidity, sealevelpressure, winddirection
    }
}

// MARK: - DataDay
struct DataDay: Codable {
    let time: [String]
    let temperatureInstant, precipitation: [Double]
    let predictability: [Int]
    let temperatureMax: [Double]
    let sealevelpressureMean: [Int]
    let windspeedMean: [Double]
    let precipitationHours, sealevelpressureMin, pictocode, snowfraction: [Int]
    let humiditygreater90Hours, convectivePrecipitation: [Double]
    let relativehumidityMax: [Int]
    let temperatureMin: [Double]
    let winddirection: [Int]
    let felttemperatureMax: [Double]
    let indexto1HvaluesEnd, relativehumidityMin: [Int]
    let felttemperatureMean, windspeedMin, felttemperatureMin: [Double]
    let precipitationProbability, uvindex, indexto1HvaluesStart: [Int]
    let rainspot: [String]
    let temperatureMean: [Double]
    let sealevelpressureMax, relativehumidityMean, predictabilityClass: [Int]
    let windspeedMax: [Double]
//    let sunrise: [String] // Format "HH:mm"
//    let sunset: [String] // Format "HH:mm"

    enum CodingKeys: String, CodingKey {
        case time
        case temperatureInstant = "temperature_instant"
        case precipitation, predictability
        case temperatureMax = "temperature_max"
        case sealevelpressureMean = "sealevelpressure_mean"
        case windspeedMean = "windspeed_mean"
        case precipitationHours = "precipitation_hours"
        case sealevelpressureMin = "sealevelpressure_min"
        case pictocode, snowfraction
        case humiditygreater90Hours = "humiditygreater90_hours"
        case convectivePrecipitation = "convective_precipitation"
        case relativehumidityMax = "relativehumidity_max"
        case temperatureMin = "temperature_min"
        case winddirection
        case felttemperatureMax = "felttemperature_max"
        case indexto1HvaluesEnd = "indexto1hvalues_end"
        case relativehumidityMin = "relativehumidity_min"
        case felttemperatureMean = "felttemperature_mean"
        case windspeedMin = "windspeed_min"
        case felttemperatureMin = "felttemperature_min"
        case precipitationProbability = "precipitation_probability"
        case uvindex
        case indexto1HvaluesStart = "indexto1hvalues_start"
        case rainspot
        case temperatureMean = "temperature_mean"
        case sealevelpressureMax = "sealevelpressure_max"
        case relativehumidityMean = "relativehumidity_mean"
        case predictabilityClass = "predictability_class"
        case windspeedMax = "windspeed_max"
//        case sunrise, sunset
    }
}
