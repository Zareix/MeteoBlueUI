//
//  MeteoData.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import Foundation
import Observation
import SwiftUI

// MARK: - MeteoData

@Observable
class MeteoData: ObservableObject {
    var location: WeatherLocation?
    var dayByDay: [MeteoDataDay] = []
    var nextHour: [MeteoData15Min] = []
    var error: String?

    private let service: MeteoBlueAPIService

    init(service: MeteoBlueAPIService = MeteoBlueAPIService()) {
        self.service = service
    }

    func loadMeteoData() async {
        await loadMeteoData(location: resolveFirstLocation())
    }

    private func resolveFirstLocation() -> WeatherLocation {
        if let location = SearchHistory().items.first {
            return location
        }
        if let location = FavoriteCities().items.first {
            return location
        }
        return LocationManager.defaultLocation()
    }

    func loadMeteoData(force: Bool = false, location: WeatherLocation, isCurrentLocation: Bool = false) async {
        do {
            if !force, self.location == location {
                return
            }
            let data = try await service.fetchForecast(location: location)

            var newDays: [MeteoDataDay] = []

            for (index, day) in data.dataDay.time.enumerated() {
                let date = MeteoData.convertStringDayToDate(input: day)
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
                        precipitationProbability: data.dataDay.precipitationProbability[index]
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
                    time: MeteoData.convertStringDayHourToTime(input: hour),
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

            self.location = location
            dayByDay = newDays
            nextHour.removeAll()
            error = nil

            if isCurrentLocation {
//                let data15min = try await service.fetch15Min(location: location)
//                for (index, hour) in data15min.data15Min.time.enumerated() {
//                    let date = MeteoData.convertStringHourToTime(
//                        input: hour
//                    )
//                    if date < Calendar.current.startOfDay(for: .now) {
//                        continue
//                    }
//                    nextHour.append(MeteoData15Min(
//                        time: MeteoData.convertStringDayHourToTime(
//                            input: hour
//                        ),
//                        temperature: data15min.data15Min.temperature[index],
//                        precipitation: data15min.data15Min.precipitation[index]
//                    ))
//                }

//                Task.detached(priority: .background) {
//                    _ = try? await WidgetDataService.fetchWidgetData(for: location)
//                    WidgetCenter.shared.reloadAllTimelines()
//                }
            }
        } catch {
            print("Error loading meteo data: \(error)")
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            self.error = error.localizedDescription
        }
    }

    static func convertStringDayHourToTime(input: String) -> Date {
        return convertStringToDate(input: input, format: "yyyy-MM-dd HH:mm")
    }

    static func convertStringDayToDate(input: String) -> Date {
        return convertStringToDate(input: input, format: "yyyy-MM-dd")
    }

    static func convertStringHourToTime(input: String) -> Date {
        return convertStringToDate(input: input, format: "HH:mm")
    }

    static func convertStringToDate(input: String, format: String) -> Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = format
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        return inputFormatter.date(from: input) ?? Date()
    }
}

// MARK: - Mock

class MockMeteoData: MeteoData {
    override func loadMeteoData(force: Bool = false, location: WeatherLocation, isCurrentLocation: Bool = false) async {
        print("Loading meteo data for \(location.city)")

        var dayByDay: [MeteoDataDay] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for index in 0...7 {
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
                        time: MeteoData.convertStringDayHourToTime(
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
                    time: MeteoData.convertStringDayToDate(
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
                    precipitationProbability: Int.random(in: 0...100)
                    //                    sunrise: MeteoData.convertStringHourToTime(
                    //                        input: "06:00"
                    //                    ),
                    //                    sunset: MeteoData.convertStringHourToTime(
                    //                        input: "20:00"
                    //                    )
                )
            )
        }

        self.location = location
        self.dayByDay = dayByDay
        error = nil
    }
}
