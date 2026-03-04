//
//  CurrentWeatherView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import SwiftUI

struct CurrentWeatherView: View {
    let currentHour: MeteoData1H

    var body: some View {
        VStack {
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
                    .id("description")
                    .transition(.opacity)
                    .animation(.easeOut, value: currentHour.description)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        CurrentWeatherView(
            currentHour: MeteoData1H(
                time: Date(),
                description: "Sunny",
                symbol: "sun.max.fill",
                temperature: 22.5,
                feltTemperature: 28,
                precipitation: 0,
                precipitationProbability: 5
            )
        )

        CurrentWeatherView(
            currentHour: MeteoData1H(
                time: Date(),
                description: "Cloudy with a risk of rain",
                symbol: "cloud.sun.rain.fill",
                temperature: 15,
                feltTemperature: 14,
                precipitation: 0,
                precipitationProbability: 5
            )
        )
    }
    .padding()
    .appBackground()
}
