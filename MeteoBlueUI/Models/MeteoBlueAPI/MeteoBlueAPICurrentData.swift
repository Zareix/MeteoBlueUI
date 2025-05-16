//
//  MeteoBlueAPICurrentData.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//
import Foundation

struct MeteoBlueAPICurrentData: Codable {
    let metadata: Metadata
    let units: Units
    let dataCurrent: DataCurrent

    enum CodingKeys: String, CodingKey {
        case metadata, units
        case dataCurrent = "data_current"
    }
}

// MARK: - DataCurrent
struct DataCurrent: Codable {
    let time: String
    let isobserveddata: Int
    let metarid: Int?
    let isdaylight: Int
    let windspeed: Double?
    let zenithangle: Double
    let pictocodeDetailed, pictocode: Int
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case time, isobserveddata, metarid, isdaylight, windspeed, zenithangle
        case pictocodeDetailed = "pictocode_detailed"
        case pictocode, temperature
    }
}

// MARK: - Metadata
struct Metadata: Codable {
    let modelrunUpdatetimeUTC, name: String
    let height: Int
    let timezoneAbbrevation: String
    let latitude: Double
    let modelrunUTC: String
    let longitude: Double
    let utcTimeoffset: Int
    let generationTimeMS: Double

    enum CodingKeys: String, CodingKey {
        case modelrunUpdatetimeUTC = "modelrun_updatetime_utc"
        case name, height
        case timezoneAbbrevation = "timezone_abbrevation"
        case latitude
        case modelrunUTC = "modelrun_utc"
        case longitude
        case utcTimeoffset = "utc_timeoffset"
        case generationTimeMS = "generation_time_ms"
    }
}

// MARK: - Units
struct Units: Codable {
    let temperature, time, windspeed: String
}
