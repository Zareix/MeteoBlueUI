//
//  HourCellView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 02/09/2026.
//

import SwiftUI

struct HourCellView: View {
    enum Style {
        case regular
        case compact
    }

    static let significantPrecipitationThreshold = 20

    let time: Date
    var isNow: Bool = false
    let symbol: String
    var description: String?
    let temperature: Double
    let precipitationProbability: Int
    var style: Style = .regular

    private let symbolBlockHeight: CGFloat = 40

    private var timeText: String {
        isNow
            ? String(localized: "hour-by-hour.now")
            : DateTimeConverter.convertTimeToHourString(input: time)
    }

    private var cellSpacing: CGFloat {
        style == .compact ? 4 : 10
    }

    private var timeFont: Font {
        style == .compact ? .caption2 : .body
    }

    private var temperatureFont: Font {
        style == .compact ? .caption : .body
    }

    var body: some View {
        VStack(spacing: cellSpacing) {
            Text(timeText)
                .font(timeFont)
                .fontWeight(style == .compact ? nil : .medium)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                SymbolView(symbol: symbol, description: description)
                    .font(.system(size: 24))
                    .frame(width: 24, height: 24)

                if precipitationProbability >= Self.significantPrecipitationThreshold {
                    Text("\(precipitationProbability)%")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
            }
            .frame(height: symbolBlockHeight)

            TemperatureView(temperature: temperature)
                .font(temperatureFont)
                .fontWeight(style == .compact ? .semibold : nil)
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 24) {
        HourCellView(
            time: .now,
            isNow: true,
            symbol: "cloud.fill",
            description: "Nuageux",
            temperature: 5,
            precipitationProbability: 0
        )
        
        HourCellView(
            time: .now,
            symbol: "cloud.rain.fill",
            description: "Averses éparses",
            temperature: 18,
            precipitationProbability: 45
        )

        HourCellView(
            time: Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now,
            symbol: "sun.max.fill",
            temperature: 21,
            precipitationProbability: 5,
            style: .compact
        )
    }
    .appBackground()
}
