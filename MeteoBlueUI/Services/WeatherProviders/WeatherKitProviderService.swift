//
//  WeatherKitProviderService.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 19/05/2026.
//

import CoreLocation
import Foundation
import OSLog
import WeatherKit

private let logger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "WeatherKitProviderService")

actor WeatherKitProviderService: WeatherProviderService {
    private var forecastTask: Task<WeatherForecast, Error>?

    func fetchForecast(location: WeatherLocation) async throws -> WeatherForecast {
        forecastTask?.cancel()

        let task = Task<WeatherForecast, Error> {
            logger.info("🌐 fetchForecast: \(location.city) lat=\(location.latitude) lon=\(location.longitude)")

            let cl = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let service = WeatherService.shared
            let weather = try await service.weather(for: cl)

            return Self.mapToDomain(weather: weather)
        }

        forecastTask = task
        return try await task.value
    }

    func fetchWidgetData(location: WeatherLocation) async throws -> WidgetData {
        return WidgetData(location: location, hours: [], savedAt: Date())
    }

    private static func mapToDomain(weather: Weather) -> WeatherForecast {
        let calendar = Calendar.current
        let hourly = weather.hourlyForecast.forecast

        var days: [MeteoDataDay] = []
        let todayStart = calendar.startOfDay(for: .now)

        for day in weather.dailyForecast.forecast {
            if day.date < todayStart {
                continue
            }

            let dayStart = calendar.startOfDay(for: day.date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? day.date

            let hourByHour: [MeteoData1H] = hourly
                .filter { $0.date >= dayStart && $0.date < dayEnd }
                .map { hour in
                    MeteoData1H(
                        time: hour.date,
                        description: hour.condition.description,
                        symbol: "\(hour.symbolName).fill",
                        temperature: hour.temperature.converted(to: .celsius).value,
                        feltTemperature: hour.apparentTemperature.converted(to: .celsius).value,
                        precipitation: hour.precipitationAmount.converted(to: .millimeters).value,
                        precipitationProbability: Int((hour.precipitationChance * 100).rounded())
                    )
                }

            let min = day.lowTemperature.converted(to: .celsius).value
            let max = day.highTemperature.converted(to: .celsius).value

            days.append(
                MeteoDataDay(
                    hourByHour: hourByHour,
                    time: dayStart,
                    description: day.condition.description,
                    symbol: "\(day.symbolName).fill",
                    temperatureMean: (min + max) / 2,
                    temperatureMin: min,
                    temperatureMax: max,
                    precipitation: day.precipitationAmountByType.precipitation.converted(to: .millimeters).value,
                    precipitationProbability: Int((day.precipitationChance * 100).rounded()),
                    predictabilityClass: 5,
                    sunrise: day.sun.sunrise ?? dayStart,
                    sunset: day.sun.sunset ?? dayStart
                )
            )
        }

        let nextHour: [MeteoData5Min] = Self.buildNextHour(minutes: weather.minuteForecast)
        return WeatherForecast(dayByDay: days, nextHour: nextHour)
    }

    private static func buildNextHour(minutes: Forecast<MinuteWeather>?) -> [MeteoData5Min] {
        guard let minutes else { return [] }
        let cutoff = Date().addingTimeInterval(-5 * 60)
        var result: [MeteoData5Min] = []
        // Bucket consecutive minutes into 5-minute groups.
        let bucketed = stride(from: 0, to: minutes.forecast.count, by: 5).map { start -> [MinuteWeather] in
            let end = Swift.min(start + 5, minutes.forecast.count)
            return Array(minutes.forecast[start ..< end])
        }
        for bucket in bucketed {
            guard let first = bucket.first else { continue }
            if first.date < cutoff { continue }
            // WeatherKit stores precipitationIntensity as Measurement<UnitSpeed>; converting to
            // kilometers/hour and scaling by 1_000_000 yields mm/h. Per-minute amount = mm/h / 60.
            let amountMM = bucket.reduce(0.0) { partial, minute in
                let mmPerHour = minute.precipitationIntensity.converted(to: .kilometersPerHour).value * 1_000_000
                return partial + mmPerHour / 60.0
            }
            result.append(MeteoData5Min(time: first.date, precipitation: amountMM))
        }
        return result
    }
}
