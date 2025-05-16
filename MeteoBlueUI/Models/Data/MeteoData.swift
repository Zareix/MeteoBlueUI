//
//  MeteoData.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//

import Foundation
import MapKit

@MainActor
class MeteoData: ObservableObject {
    @Published var city: MKMapItem?
    @Published var dayByDay: [MeteoDataDay] = []
    @Published var hourByHour: [MeteoData1H] = []
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
            self.hourByHour.removeAll()
            self.dayByDay.removeAll()
            self.error = nil
            for (index, hour) in data.data1H.time.enumerated() {
                let date = MeteoData.convertStringToTime(input: hour)
                if date < Date() {
                    continue
                }
                if date > Date().addingTimeInterval(24 * 3600) {
                    break
                }
                if hourByHour.isEmpty {
                    hourByHour.append(
                        MeteoData1H(
                            time: MeteoData.convertStringToTime(
                                input: data.data1H.time[index - 1]
                            ),
                            description: PictoMapper.pictoToDescription(
                                picto: data.data1H.pictocode[index - 1]
                            ),
                            symbol: PictoMapper.pictoToSFSymbol(
                                picto: data.data1H.pictocode[index - 1],
                                isDaylight: data.data1H.isdaylight[index - 1]
                                    == 0 ? false : true
                            ),
                            temperature: data.data1H.temperature[index - 1]
                        )
                    )
                }
                hourByHour.append(
                    MeteoData1H(
                        time: MeteoData.convertStringToTime(
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
                )
            }

            for (index, day) in data.dataDay.time.enumerated() {
                self.dayByDay.append(
                    MeteoDataDay(
                        time: MeteoData.convertStringToDate(
                            input: day
                        ),
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
                    )
                )
            }
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            self.error = error.localizedDescription
        }
    }

    static func convertStringToTime(input: String, ) -> Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        return inputFormatter.date(from: input) ?? Date()
    }

    static func convertStringToDate(input: String, ) -> Date {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        return inputFormatter.date(from: input) ?? Date()
    }

}

struct MeteoData1H {
    let time: Date
    let description: String
    let symbol: String
    let temperature: Double
}

struct MeteoDataDay {
    let time: Date
    let description: String
    let symbol: String
    let temperatureMean: Double
    let temperatureMin: Double
    let temperatureMax: Double
    let precipitation: Double
}

// MARK: - Mock
class MockMeteoData: MeteoData {
    override func loadMeteoData(force: Bool = false, city: MKMapItem) async {
        print("Loading meteo data for \(city.placemark.locality ?? "Unknown")")
        self.city = city
        self.hourByHour.removeAll()
        self.dayByDay.removeAll()
        for index in 1...22 {
            let picto = Int.random(in: 1...35)
            self.hourByHour.append(
                MeteoData1H(
                    time: MeteoData.convertStringToTime(
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
        for index in 1...5 {
            let picto = Int.random(in: 1...17)
            self.dayByDay.append(
                MeteoDataDay(
                    time: MeteoData.convertStringToDate(
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
                )
            )
        }
    }
}
