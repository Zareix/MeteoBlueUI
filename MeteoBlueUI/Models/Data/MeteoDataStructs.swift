//
//  MeteoDataStructs.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 04/03/2026.
//

import Foundation

// MARK: - MeteoData1H

struct MeteoData1H: Identifiable, Equatable, Hashable {
    let time: Date
    let description: String
    let symbol: String
    let temperature: Double
    let feltTemperature: Double
    let precipitation: Double
    let precipitationProbability: Int

    var id: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.string(from: time)
    }

    static func == (lhs: MeteoData1H, rhs: MeteoData1H) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - MeteoDataDay

struct MeteoDataDay: Identifiable, Equatable, Hashable {
    var hourByHour: [MeteoData1H]

    let time: Date
    let description: String
    let symbol: String
    let temperatureMean: Double
    let temperatureMin: Double
    let temperatureMax: Double
    let precipitation: Double
    let precipitationProbability: Int

    var id: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: time)
    }

    static func == (lhs: MeteoDataDay, rhs: MeteoDataDay) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - MeteoData15Min

struct MeteoData15Min: Identifiable, Equatable {
    let time: Date
    let temperature: Double
    let precipitation: Double

    var id: Date {
        time
    }

    static func == (lhs: MeteoData15Min, rhs: MeteoData15Min) -> Bool {
        lhs.id == rhs.id
    }
}
