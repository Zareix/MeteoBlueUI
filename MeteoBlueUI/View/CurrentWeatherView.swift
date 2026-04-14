//
//  CurrentWeatherView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import SwiftUI

struct CurrentWeatherView: View {
    let firstDay: MeteoDataDay

    private var currentHour: MeteoData1H? {
        let now = Date()
        return firstDay.hourByHour.min { lhs, rhs in
            abs(lhs.time.timeIntervalSince(now)) < abs(rhs.time.timeIntervalSince(now))
        }
    }

    var body: some View {
        VStack {
            if let currentHour {
                VStack {
                    HStack(spacing: 20) {
                        SymbolView(symbol: currentHour.symbol,
                                   description: currentHour.description)
                            .font(.system(size: 50))
                            .frame(height: 54)

                        TemperatureView(temperature: currentHour.temperature)
                            .font(.system(size: 50))
                    }

                    if abs(currentHour.feltTemperature - currentHour.temperature) >= 3 {
                        HStack(spacing: 4) {
                            Text("feels")
                            TemperatureView(temperature: currentHour.feltTemperature)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Text(currentHour.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                        .animation(.easeOut, value: currentHour.description)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        CurrentWeatherView(
            firstDay: MeteoDataDay(
                hourByHour: [
                    MeteoData1H(
                        time: Date(),
                        description: "Sunny",
                        symbol: "sun.max.fill",
                        temperature: 22.5,
                        feltTemperature: 28,
                        precipitation: 0,
                        precipitationProbability: 5
                    )
                ],
                time: Date(),
                description: "Sunny with some clouds in the afternoon",
                symbol: "sun.max.fill",
                temperatureMean: 20,
                temperatureMin: 15,
                temperatureMax: 25,
                precipitation: 0,
                precipitationProbability: 5
            )
        )

        CurrentWeatherView(
            firstDay: MeteoDataDay(
                hourByHour: [MeteoData1H(
                    time: Date(),
                    description: "Cloudy with a risk of rain",
                    symbol: "cloud.sun.rain.fill",
                    temperature: 15,
                    feltTemperature: 14,
                    precipitation: 0,
                    precipitationProbability: 5
                )],
                time: Date(),
                description: "Cloudy with a risk of rain",
                symbol: "cloud.sun.rain.fill",
                temperatureMean: 15,
                temperatureMin: 10,
                temperatureMax: 20,
                precipitation: 0,
                precipitationProbability: 5
            )
        )
    }
    .padding()
    .appBackground()
}
