//
//  OpenMeteoProviderService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 31/07/2026.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "OpenMeteoProviderService")

/// Uses Open-Meteo's best-match model selection — free, no API key, plain JSON.
actor OpenMeteoProviderService: WeatherProviderService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    private var forecastTask: Task<WeatherForecast, Error>?

    func fetchForecast(location: WeatherLocation) async throws -> WeatherForecast {
        forecastTask?.cancel()

        let task = Task<WeatherForecast, Error> {
            let raw = try await fetchRawForecast(location: location)
            return Self.mapToDomain(raw)
        }

        forecastTask = task
        return try await task.value
    }

    func fetchWidgetData(location: WeatherLocation) async throws -> WidgetData {
        var components = Self.baseComponents(location: location)
        components.queryItems?.append(contentsOf: [
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,weathercode,is_day"),
            URLQueryItem(name: "forecast_days", value: "2"),
        ])
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        try Self.checkResponse(response)

        let forecast = try JSONDecoder().decode(OpenMeteoHourlyForecast.self, from: data)
        let currentHourStart = Calendar.current.dateInterval(of: .hour, for: Date())?.start ?? Date()

        let hours: [WidgetHourEntry] = forecast.hourly.time.enumerated().compactMap { index, timeStr in
            let date = DateTimeConverter.convertISODayHourToTime(input: timeStr)
            guard date >= currentHourStart,
                  let code = forecast.hourly.weathercode[index],
                  let isDay = forecast.hourly.isDay[index],
                  let temperature = forecast.hourly.temperature2M[index]
            else { return nil }
            return WidgetHourEntry(
                time: date,
                symbol: WMOWeatherMapper.sfSymbol(code: code, isDaylight: isDay != 0),
                description: WMOWeatherMapper.description(code: code),
                temperature: temperature,
                precipitationProbability: forecast.hourly.precipitationProbability[index] ?? 0
            )
        }

        return WidgetData(location: location, hours: hours, savedAt: Date())
    }

    private func fetchRawForecast(location: WeatherLocation) async throws -> OpenMeteoForecast {
        logger.info("🌐 fetchForecast: \(location.city) lat=\(location.latitude) lon=\(location.longitude)")

        var components = Self.baseComponents(location: location)
        components.queryItems?.append(contentsOf: [
            URLQueryItem(
                name: "hourly",
                value: "temperature_2m,apparent_temperature,precipitation,precipitation_probability,weathercode,is_day"
            ),
            URLQueryItem(
                name: "daily",
                value: "weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,sunrise,sunset"
            ),
            URLQueryItem(name: "forecast_days", value: "7"),
        ])
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        try Self.checkResponse(response)

        return try JSONDecoder().decode(OpenMeteoForecast.self, from: data)
    }

    private static func baseComponents(location: WeatherLocation) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.open-meteo.com"
        components.path = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "timezone", value: TimeZone.current.identifier),
        ]
        return components
    }

    private static func checkResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200 ... 299: break
        case 429: throw AppError.rateLimitExceeded
        default: throw AppError.httpError(http.statusCode)
        }
    }

    private static func mapToDomain(_ data: OpenMeteoForecast) -> WeatherForecast {
        let todayStart = Calendar.current.startOfDay(for: .now)

        var days: [MeteoDataDay] = data.daily.time.enumerated().compactMap { index, dayStr in
            let date = DateTimeConverter.convertStringDayToDate(input: dayStr)
            guard date >= todayStart,
                  let code = data.daily.weathercode[index],
                  let min = data.daily.temperature2MMin[index],
                  let max = data.daily.temperature2MMax[index],
                  let precipitation = data.daily.precipitationSum[index]
            else { return nil }

            return MeteoDataDay(
                hourByHour: [],
                time: date,
                description: WMOWeatherMapper.description(code: code),
                symbol: WMOWeatherMapper.sfSymbol(code: code, isDaylight: true),
                temperatureMean: (min + max) / 2,
                temperatureMin: min,
                temperatureMax: max,
                precipitation: precipitation,
                // Some models Open-Meteo picks per point don't expose a probability; default to 0.
                precipitationProbability: data.daily.precipitationProbabilityMax[index] ?? 0,
                predictabilityClass: 5,
                sunrise: DateTimeConverter.convertISODayHourToTime(input: data.daily.sunrise[index]),
                sunset: DateTimeConverter.convertISODayHourToTime(input: data.daily.sunset[index])
            )
        }

        for (index, hourStr) in data.hourly.time.enumerated() {
            let hourDate = DateTimeConverter.convertISODayHourToTime(input: hourStr)
            guard let dayIndex = days.firstIndex(where: { Calendar.current.isDate($0.time, inSameDayAs: hourDate) }),
                  let code = data.hourly.weathercode[index],
                  let isDay = data.hourly.isDay[index],
                  let temperature = data.hourly.temperature2M[index],
                  let feltTemperature = data.hourly.apparentTemperature[index],
                  let precipitation = data.hourly.precipitation[index]
            else { continue }

            days[dayIndex].hourByHour.append(
                MeteoData1H(
                    time: hourDate,
                    description: WMOWeatherMapper.description(code: code),
                    symbol: WMOWeatherMapper.sfSymbol(code: code, isDaylight: isDay != 0),
                    temperature: temperature,
                    feltTemperature: feltTemperature,
                    precipitation: precipitation,
                    // Some models Open-Meteo picks per point don't expose a probability; default to 0.
                    precipitationProbability: data.hourly.precipitationProbability[index] ?? 0
                )
            )
        }

        // ponytail: Open-Meteo has no 5-minute nowcast; leave empty, same as WeatherKitProviderService
        // does when WeatherKit's minute forecast is unavailable.
        return WeatherForecast(dayByDay: days, nextHour: [])
    }
}
