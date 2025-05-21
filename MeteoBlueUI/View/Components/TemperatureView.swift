//
//  TemperatureView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 21/05/2025.
//
import SwiftUI

struct TemperatureView: View {
    let temperature: Double
    
    var body: some View {
        Text(
            "\(Int(round(temperature)))°"
        )
        .contentTransition(.numericText())
        .animation(
            .easeInOut,
            value: temperature
        )
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var temperature = Double.random(in: -10...35)

    VStack {
        HStack(spacing: 32) {
            TemperatureView(temperature: temperature)

            TemperatureView(temperature: temperature)
                .font(.title2)

            TemperatureView(temperature: temperature)
                .font(.title2)

        }

        Button("Refresh") {
            withAnimation {
                temperature = Double.random(in: -10...35)
            }
        }
    }
}
