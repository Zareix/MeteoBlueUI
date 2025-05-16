//
//  MeteoData.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//

import Foundation
import MapKit

// MARK: - Struct
struct MeteoData1H {
    let time: Date
    let description: String
    let symbol: String
    let temperature: Double
}

struct MeteoDataDay: Identifiable, Equatable {
    let id: String
    var hourByHour: [MeteoData1H]

    let time: Date
    let description: String
    let symbol: String
    let temperatureMean: Double
    let temperatureMin: Double
    let temperatureMax: Double
    let precipitation: Double
    //    let sunrise: Date
    //    let sunset: Date

    static func == (lhs: MeteoDataDay, rhs: MeteoDataDay) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - MeteoData
@MainActor
class MeteoData: ObservableObject {
    @Published var city: MKMapItem?
    @Published var dayByDay: [MeteoDataDay] = []
    @Published var error: String?

    func loadMeteoData(force: Bool = false, city: MKMapItem) async {
        do {
            if self.city != nil && !force && self.city == city {
                return
            }
            let data = try await MeteoBlueAPIService().fetchForecast(
                city: city
            )
            self.city = city
            self.dayByDay.removeAll()
            self.error = nil

            for (index, day) in data.dataDay.time.enumerated() {
                let date = MeteoData.convertStringDayToDate(
                    input: day
                )
                if date < Calendar.current.startOfDay(for: .now) {
                    continue
                }
                self.dayByDay.append(
                    MeteoDataDay(
                        id: day,
                        hourByHour: [],
                        time: date,
                        description: PictoMapper.pictoIdayToDescription(
                            picto: data.dataDay.pictocode[index]
                        ),
                        symbol: PictoMapper.pictoIdayToSFSymbol(
                            picto: data.dataDay.pictocode[index],
                        ),
                        temperatureMean: data.dataDay.temperatureMean[index],
                        temperatureMin: data.dataDay.temperatureMin[index],
                        temperatureMax: data.dataDay.temperatureMax[index],
                        precipitation: data.dataDay.precipitation[index]
                        //                        sunrise: MeteoData.convertStringHourToTime(
                        //                            input: data.dataDay.time[index]
                        //                        ),
                        //                        sunset: MeteoData.convertStringHourToTime(
                        //                            input: data.dataDay.time[index]
                        //                        )
                    )
                )
            }
            for (index, hour) in data.data1H.time.enumerated() {
                let day = dayByDay.first { day in
                    return hour.contains(day.id)
                }
                guard var day else {
                    continue
                }
                let date = MeteoData.convertStringDayHourToTime(input: hour)
                if date < Date() {
                    continue
                }
                if dayByDay.first == day && day.hourByHour.isEmpty {
                    day.hourByHour.append(
                        MeteoData1H(
                            time: MeteoData.convertStringDayHourToTime(
                                input: data.data1H.time[index - 1]
                            ),
                            description: PictoMapper.pictoToDescription(
                                picto: data.data1H.pictocode[index - 1]
                            ),
                            symbol: PictoMapper.pictoToSFSymbol(
                                picto: data.data1H.pictocode[index - 1],
                                isDaylight: data.data1H.isdaylight[index - 1]
                                    == 0
                                    ? false : true
                            ),
                            temperature: data.data1H.temperature[index - 1]
                        )
                    )
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
                    temperature: data.data1H.temperature[index]
                )
                day.hourByHour.append(
                    hourData
                )
                self.dayByDay[self.dayByDay.firstIndex(of: day)!] = day
            }
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            self.error = error.localizedDescription
        }
    }

    static func convertStringDayHourToTime(input: String, ) -> Date {
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
    override func loadMeteoData(force: Bool = false, city: MKMapItem) async {
        print("Loading meteo data for \(city.placemark.locality ?? "Unknown")")
        self.city = city
        self.dayByDay.removeAll()
        for index in 1...5 {
            var hourByHour: [MeteoData1H] = []
            for index in 1...22 {
                let picto = Int.random(in: 1...35)
                hourByHour.append(
                    MeteoData1H(
                        time: MeteoData.convertStringDayHourToTime(
                            input: "2025-05-13 \(index):00"
                        ),
                        description: PictoMapper.pictoToDescription(
                            picto: picto
                        ),
                        symbol: PictoMapper.pictoToSFSymbol(
                            picto: picto,
                            isDaylight: Bool.random()
                        ),
                        temperature: Double.random(in: 0...30)
                    )
                )
            }
            let picto = Int.random(in: 1...17)
            self.dayByDay.append(
                MeteoDataDay(
                    id: "2025-05-\(index)",
                    hourByHour: hourByHour,
                    time: MeteoData.convertStringDayToDate(
                        input: "2025-05-\(index)"
                    ),
                    description: PictoMapper.pictoIdayToDescription(
                        picto: picto
                    ),
                    symbol: PictoMapper.pictoIdayToSFSymbol(
                        picto: picto,
                    ),
                    temperatureMean: Double.random(in: 0...30),
                    temperatureMin: Double.random(in: 0...15),
                    temperatureMax: Double.random(in: 15...30),
                    precipitation: Double.random(in: 0...10)
                    //                    sunrise: MeteoData.convertStringHourToTime(
                    //                        input: "06:00"
                    //                    ),
                    //                    sunset: MeteoData.convertStringHourToTime(
                    //                        input: "20:00"
                    //                    )
                )
            )
        }
    }
}
