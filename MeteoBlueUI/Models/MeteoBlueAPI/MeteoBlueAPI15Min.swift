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
    let data15Min: Data15Min

    enum CodingKeys: String, CodingKey {
        case data15Min = "data_xmin"
    }
}

// MARK: - Data15Min

struct Data15Min: Codable {
    let time: [String]
    let temperature: [Double]
    let precipitation: [Double]

    enum CodingKeys: String, CodingKey {
        case time, temperature, precipitation
    }
}
