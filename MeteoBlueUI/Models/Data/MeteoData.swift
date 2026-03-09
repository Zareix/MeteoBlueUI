//
//  MeteoData.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import Foundation
import SwiftUI

// MARK: - MeteoData

@MainActor
class MeteoData: ObservableObject {
    @Published var location: WeatherLocation?
    @Published var dayByDay: [MeteoDataDay] = []
    @Published var nextHour: [MeteoData15Min] = []
    @Published var error: String?

    private let service: MeteoBlueAPIService
    var locationManager: LocationManager?

    init(service: MeteoBlueAPIService = MeteoBlueAPIService()) {
        self.service = service
    }

    func loadMeteoData() async {
        if let fallback = await resolveFallbackLocation() {
            await loadMeteoData(location: fallback)
        }

        guard let manager = locationManager else { return }
        let gpsLocation: WeatherLocation? = await withTaskGroup(of: WeatherLocation?.self) { group in
            group.addTask { @MainActor in
                for await location: WeatherLocation? in manager.$currentLocation.values {
                    if let location { return location }
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                return nil
            }
            for await result in group {
                if let location = result {
                    group.cancelAll()
                    return location
                }
            }
            group.cancelAll()
            return nil
        }

        if let gpsLocation {
            await loadMeteoData(location: gpsLocation, isCurrentLocation: true)
        }
    }

    private func resolveFallbackLocation() async -> WeatherLocation? {
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
            if self.location != nil, !force, self.location == location {
                return
            }
            let data = try await service.fetchForecast(location: location)
            withAnimation(.easeInOut(duration: 0.4)) {
                self.location = location
            }
            dayByDay.removeAll()
            error = nil

            for (index, day) in data.dataDay.time.enumerated() {
                let date = MeteoData.convertStringDayToDate(
                    input: day
                )
                if date < Calendar.current.startOfDay(for: .now) {
                    continue
                }
                dayByDay.append(
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
                        precipitationProbability: data.dataDay
                            .precipitationProbability[index]
                    )
                )
            }
            for (index, hour) in data.data1H.time.enumerated() {
                let day = dayByDay.first { day in
                    hour.contains(day.id)
                }
                guard var day else {
                    continue
                }
                let hourData = MeteoData1H(
                    time: MeteoData.convertStringDayHourToTime(
                        input: hour
                    ),
                    description: PictoMapper.pictoToDescription(
                        picto: data.data1H.pictocode[index]
                    ),
                    symbol: PictoMapper.pictoToSFSymbol(
                        picto: data.data1H.pictocode[index],
                        isDaylight: data.data1H.isdaylight[index] == 0
                            ? false : true
                    ),
                    temperature: data.data1H.temperature[index],
                    feltTemperature: data.data1H.felttemperature[index],
                    precipitation: data.data1H.precipitation[index],
                    precipitationProbability: data.data1H
                        .precipitationProbability[index]
                )
                day.hourByHour.append(
                    hourData
                )
                guard let dayIndex = dayByDay.firstIndex(of: day) else {
                    continue
                }
                dayByDay[dayIndex] = day
            }

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
        await Task.yield()
        self.location = location
        dayByDay.removeAll()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for index in 0...7 {
            let day = dateFormatter.string(
                from: Calendar.current
                    .startOfDay(for: Date())
                    .addingTimeInterval(TimeInterval(index * 24 * 60 * 60))
            )

            // Mock Hour By Hour
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

        // Mock Next Hour (15min by 15min)
//        for index in 0...200 {
//            nextHour.append(
//                MeteoData15Min(
//                    time: Date().addingTimeInterval(TimeInterval(index * 15 * 60)),
//                    temperature: Double.random(in: -5...30),
//                    precipitation: Double.random(in: 0...20)
//                )
//            )
//        }
    }
}
