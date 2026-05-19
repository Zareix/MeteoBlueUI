//
//  MeteoBlueProviderService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "MeteoBlueProviderService")

actor MeteoBlueProviderService: WeatherProviderService {
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
        guard let token = KeychainService().getMetoBlueAPIToken() else {
            throw AppError.noAPIToken
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "my.meteoblue.com"
        components.path = "/packages/basic-1h"
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.latitude)),
            URLQueryItem(name: "lon", value: String(location.longitude)),
            URLQueryItem(name: "apikey", value: token),
            URLQueryItem(name: "tz", value: TimeZone.current.identifier),
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200 ... 299: break
            case 401: throw AppError.invalidAPIToken
            case 429: throw AppError.rateLimitExceeded
            default: throw AppError.httpError(http.statusCode)
            }
        }

        let forecast = try JSONDecoder().decode(MeteoBlueAPIForecast.self, from: data)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let currentHourStart = Calendar.current.dateInterval(of: .hour, for: Date())?.start ?? Date()

        let hours: [WidgetHourEntry] = forecast.data1H.time.enumerated().compactMap { index, timeStr in
            let date = formatter.date(from: timeStr) ?? Date()
            guard date >= currentHourStart else { return nil }
            return WidgetHourEntry(
                time: date,
                symbol: PictoMapper.pictoToSFSymbol(
                    picto: forecast.data1H.pictocode[index],
                    isDaylight: forecast.data1H.isdaylight[index] != 0
                ),
                description: PictoMapper.pictoToDescription(picto: forecast.data1H.pictocode[index]),
                temperature: forecast.data1H.temperature[index],
                precipitationProbability: forecast.data1H.precipitationProbability[index]
            )
        }

        return WidgetData(location: location, hours: hours, savedAt: Date())
    }

    private func fetchRawForecast(location: WeatherLocation) async throws -> MeteoBlueAPIForecast {
        let (lat, lon) = (location.latitude, location.longitude)
        logger.info("🌐 fetchForecast: \(location.city) lat=\(lat) lon=\(lon)")

        guard let token = KeychainService().getMetoBlueAPIToken() else {
            logger.error("❌ fetchForecast: no API token in keychain — widget cannot fetch")
            throw AppError.noAPIToken
        }
        logger.info("🔑 fetchForecast: API token found (\(token.prefix(4))…)")

        var components = URLComponents()
        components.scheme = "https"
        components.host = "my.meteoblue.com"
        components.path = "/packages/basic-1h,basic-day,basic-5min,sunmoon"
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "apikey", value: token),
            URLQueryItem(name: "tz", value: TimeZone.current.identifier),
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200 ... 299: break
            case 401: throw AppError.invalidAPIToken
            case 429: throw AppError.rateLimitExceeded
            default: throw AppError.httpError(http.statusCode)
            }
        }

        return try JSONDecoder().decode(MeteoBlueAPIForecast.self, from: data)
    }

    private static func mapToDomain(_ data: MeteoBlueAPIForecast) -> WeatherForecast {
        var newDays: [MeteoDataDay] = []

        for (index, day) in data.dataDay.time.enumerated() {
            let date = DateTimeConverter.convertStringDayToDate(input: day)
            if date < Calendar.current.startOfDay(for: .now) {
                continue
            }
            newDays.append(
                MeteoDataDay(
                    hourByHour: [],
                    time: date,
                    description: PictoMapper.pictoIdayToDescription(
                        picto: data.dataDay.pictocode[index]
                    ),
                    symbol: PictoMapper.pictoIdayToSFSymbol(
                        picto: data.dataDay.pictocode[index]
                    ),
                    temperatureMean: data.dataDay.temperatureMean[index],
                    temperatureMin: data.dataDay.temperatureMin[index],
                    temperatureMax: data.dataDay.temperatureMax[index],
                    precipitation: data.dataDay.precipitation[index],
                    precipitationProbability: data.dataDay.precipitationProbability[index],
                    predictabilityClass: data.dataDay.predictabilityClass[index],
                    sunrise: DateTimeConverter.combineDayAndTime(day: date, time: data.dataDay.sunrise[index]),
                    sunset: DateTimeConverter.combineDayAndTime(day: date, time: data.dataDay.sunset[index])
                )
            )
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for (index, hour) in data.data1H.time.enumerated() {
            let day = newDays.first { day in
                hour.contains(dateFormatter.string(from: day.time))
            }
            guard var day else {
                continue
            }

            let hourData = MeteoData1H(
                time: DateTimeConverter.convertStringDayHourToTime(input: hour),
                description: PictoMapper.pictoToDescription(
                    picto: data.data1H.pictocode[index]
                ),
                symbol: PictoMapper.pictoToSFSymbol(
                    picto: data.data1H.pictocode[index],
                    isDaylight: data.data1H.isdaylight[index] == 0 ? false : true
                ),
                temperature: data.data1H.temperature[index],
                feltTemperature: data.data1H.felttemperature[index],
                precipitation: data.data1H.precipitation[index],
                precipitationProbability: data.data1H.precipitationProbability[index]
            )

            day.hourByHour.append(hourData)

            guard let dayIndex = newDays.firstIndex(of: day) else {
                continue
            }
            newDays[dayIndex] = day
        }

        var nextHour: [MeteoData5Min] = []
        let cutoff = Date().addingTimeInterval(-5 * 60)
        for (index, hour) in data.data5Min.time.enumerated() {
            let date = DateTimeConverter.convertStringDayHourToTime(input: hour)
            if date < cutoff {
                continue
            }
            nextHour.append(MeteoData5Min(
                time: date,
                precipitation: data.data5Min.precipitation[index]
            ))
        }

        return WeatherForecast(dayByDay: newDays, nextHour: nextHour)
    }
}
