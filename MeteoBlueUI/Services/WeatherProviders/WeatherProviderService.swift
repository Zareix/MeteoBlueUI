//
//  WeatherProviderService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 19/05/2026.
//

import Foundation

protocol WeatherProviderService: Sendable {
    func fetchForecast(location: WeatherLocation) async throws -> WeatherForecast
    func fetchWidgetData(location: WeatherLocation) async throws -> WidgetData
}

struct WeatherForecast {
    let dayByDay: [MeteoDataDay]
    let nextHour: [MeteoData5Min]
}
