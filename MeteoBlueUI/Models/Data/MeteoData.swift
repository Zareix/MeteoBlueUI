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

    private let service: MeteoBlueAPIService

    init(service: MeteoBlueAPIService = MeteoBlueAPIService()) {
        self.service = service
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
                        precipitationProbability: data.dataDay.precipitationProbability[index],
                        predictabilityClass: data.dataDay.predictabilityClass[index],
                        sunrise: MeteoData.combineDayAndTime(day: date, time: data.dataDay.sunrise[index]),
                        sunset: MeteoData.combineDayAndTime(day: date, time: data.dataDay.sunset[index])
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

            let cutoff = Date().addingTimeInterval(-5 * 60)
            for (index, hour) in data.data5Min.time.enumerated() {
                let date = MeteoData.convertStringDayHourToTime(input: hour)
                if date < cutoff {
                    continue
                }
                nextHour.append(MeteoData5Min(
                    time: date,
                    temperature: data.data5Min.temperature[index],
                    precipitation: data.data5Min.precipitation[index]
                ))
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

    static func combineDayAndTime(day: Date, time: String) -> Date {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1])
        else {
            return day
        }
        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        ) ?? day
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
                    precipitationProbability: Int.random(in: 0...100),
                    predictabilityClass: Int.random(in: 1...5),
                    sunrise: MeteoData.combineDayAndTime(
                        day: MeteoData.convertStringDayToDate(input: day),
                        time: "06:00"
                    ),
                    sunset: MeteoData.combineDayAndTime(
                        day: MeteoData.convertStringDayToDate(input: day),
                        time: "20:00"
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
            let previousTemp =
                nextHour.last?.temperature ?? Double.random(in: -5...30)
            nextHour.append(
                MeteoData5Min(
                    time: startDate.addingTimeInterval(TimeInterval(index * 5 * 60)),
                    temperature: previousTemp + Double.random(in: -0.3...0.3),
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
