//
//  MeteoBlueAPI15Min.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 06/03/2026.
//

// Response model for the basic-15min MeteoBlue package.
// Docs: https://docs.meteoblue.com/en/meteo/api/packages-overview

import Foundation

// MARK: - MeteoBlueAPI15Min

struct MeteoBlueAPI15Min: Codable {
    let metadata: Metadata
    let units: Units15Min
    let data15Min: Data15Min

    enum CodingKeys: String, CodingKey {
        case metadata, units
        case data15Min = "data_15min"
    }
}

// MARK: - Units15Min

struct Units15Min: Codable {
    let time: String
    let precipitation: String
    let precipitationProbability: String

    enum CodingKeys: String, CodingKey {
        case time, precipitation
        case precipitationProbability = "precipitation_probability"
    }
}

// MARK: - Data15Min

struct Data15Min: Codable {
    let time: [String]
    let precipitation: [Double]
    let precipitationProbability: [Int]

    enum CodingKeys: String, CodingKey {
        case time, precipitation
        case precipitationProbability = "precipitation_probability"
    }
}
