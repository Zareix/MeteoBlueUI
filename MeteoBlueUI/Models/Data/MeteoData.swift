//
//  MeteoData.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import Foundation
import Observation
import SwiftUI
import WidgetKit

// MARK: - MeteoData

@Observable
class MeteoData: ObservableObject {
    var location: WeatherLocation?
    var dayByDay: [MeteoDataDay] = []
    var nextHour: [MeteoData5Min] = []
    var error: String?

    private var provider: WeatherProviderService

    init(provider: WeatherProviderService = MeteoData.makeDefaultProvider()) {
        self.provider = provider
    }

    static func makeDefaultProvider() -> WeatherProviderService {
        switch WeatherProviderType.current {
        case .meteoblue: return MeteoBlueProviderService()
        case .weatherkit: return WeatherKitProviderService()
        }
    }

    func setProvider(_ provider: WeatherProviderService) {
        self.provider = provider
    }

    func loadMeteoData() async {
        await loadMeteoData(location: resolveFirstLocation())
    }

    private func resolveFirstLocation() -> WeatherLocation {
        if let location = FavoriteCities().items.first {
            return location
        }
        if let location = SearchHistory().items.first {
            return location
        }
        return LocationManager.defaultLocation()
    }

    func loadMeteoData(force: Bool = false, location: WeatherLocation, isCurrentLocation: Bool = false) async {
        do {
            if !force, self.location == location {
                return
            }
            let forecast = try await provider.fetchForecast(location: location)
            self.location = location
            dayByDay = forecast.dayByDay
            nextHour = forecast.nextHour
            error = nil
        } catch {
            print("Error loading meteo data: \(error)")
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Mock

class MockMeteoData: MeteoData {
    override func loadMeteoData(force: Bool = false, location: WeatherLocation, isCurrentLocation: Bool = false) async {
        print("Loading meteo data for \(location.city)")

        var dayByDay: [MeteoDataDay] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for index in 0...10 {
            let day = dateFormatter.string(
                from: Calendar.current
                    .startOfDay(for: Date())
                    .addingTimeInterval(TimeInterval(index * 24 * 60 * 60))
            )

            var hourByHour: [MeteoData1H] = []
            for index2 in 0...23 {
                let picto = Int.random(in: 1...35)
                let previousTempMean =
                    hourByHour.last?.temperature ?? Double.random(in: -5...30)
                let previousPrecipitationProb =
                    hourByHour.last?.precipitationProbability
                        ?? Int.random(in: 0...100)
                hourByHour.append(
                    MeteoData1H(
                        time: DateTimeConverter.convertStringDayHourToTime(
                            input: String(format: "%@ %02d:00", day, index2)
                        ),
                        description: PictoMapper.pictoToDescription(
                            picto: picto
                        ),
                        symbol: PictoMapper.pictoToSFSymbol(
                            picto: picto,
                            isDaylight: Bool.random()
                        ),
                        temperature: previousTempMean
                            + Double.random(in: -2...2),
                        feltTemperature: previousTempMean
                            + Double.random(in: -5...5),
                        precipitation: Double.random(in: 0...20),
                        precipitationProbability: previousPrecipitationProb < 10
                            ? previousPrecipitationProb + Int.random(in: 0...20)
                            : previousPrecipitationProb > 90
                            ? previousPrecipitationProb
                            + Int.random(in: -20...0)
                            : previousPrecipitationProb
                            + Int.random(in: -10...10)
                    )
                )
            }

            // Mock Day By Day
            let picto = Int.random(in: 1...17)
            dayByDay.append(
                MeteoDataDay(
                    hourByHour: hourByHour,
                    time: DateTimeConverter.convertStringDayToDate(
                        input: day
                    ),
                    description: PictoMapper.pictoIdayToDescription(
                        picto: picto
                    ),
                    symbol: PictoMapper.pictoIdayToSFSymbol(
                        picto: picto
                    ),
                    temperatureMean: hourByHour.map { $0.temperature }.reduce(
                        0,
                        +
                    ) / Double(hourByHour.count),
                    temperatureMin: hourByHour.map { $0.temperature }.min()
                        ?? 0,
                    temperatureMax: hourByHour.map { $0.temperature }.max()
                        ?? 0,
                    precipitation: Double.random(in: 0...20),
                    precipitationProbability: Int.random(in: 0...100),
                    predictabilityClass: Int.random(in: 1...5),
                    sunrise: DateTimeConverter.combineDayAndTime(
                        day: DateTimeConverter.convertStringDayToDate(input: day),
                        time: "06:32"
                    ),
                    sunset: DateTimeConverter.combineDayAndTime(
                        day: DateTimeConverter.convertStringDayToDate(input: day),
                        time: "20:18"
                    )
                )
            )
        }

        var nextHour: [MeteoData5Min] = []
        let now = Date()
        let currentMinute = Calendar.current.component(.minute, from: now)
        let alignedMinute = currentMinute - (currentMinute % 5)
        let startDate = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: now),
            minute: alignedMinute,
            second: 0,
            of: now
        ) ?? now
        for index in 0...23 {
            nextHour.append(
                MeteoData5Min(
                    time: startDate.addingTimeInterval(TimeInterval(index * 5 * 60)),
                    precipitation: Double.random(in: 0...0.5)
                )
            )
        }

        self.location = location
        self.dayByDay = dayByDay
        self.nextHour = nextHour
        error = nil
    }
}
