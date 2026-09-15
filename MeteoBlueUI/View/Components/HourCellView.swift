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
        // Format réduit pour le widget rectangulaire de l'Apple Watch.
        case mini
    }

    static let significantPrecipitationThreshold = 20

    let time: Date
    var isNow: Bool = false
    let symbol: String
    var description: String?
    let temperature: Double
    let precipitationProbability: Int
    var style: Style = .regular

    private var symbolBlockHeight: CGFloat {
        style == .mini ? 15 : 40
    }

    private var symbolSize: CGFloat {
        style == .mini ? 13 : 24
    }

    private var timeText: String {
        isNow
            ? String(localized: "hour-by-hour.now")
            : DateTimeConverter.convertTimeToHourString(input: time)
    }

    private var cellSpacing: CGFloat {
        switch style {
        case .compact: 4
        case .mini: 2
        default: 10
        }
    }

    private var timeFont: Font {
        switch style {
        case .regular: .body
        case .compact: .caption2
        case .mini: .system(size: 9)
        }
    }

    private var temperatureFont: Font {
        switch style {
        case .compact: .caption
        case .mini: .system(size: 10)
        default: .body
        }
    }

    var body: some View {
        VStack(spacing: cellSpacing) {
            Text(timeText)
                .font(timeFont)
                .fontWeight(style == .regular ? .medium : nil)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                SymbolView(symbol: symbol, description: description)
                    .font(.system(size: symbolSize))
                    .frame(width: symbolSize, height: symbolSize)

                if style != .mini && precipitationProbability >= Self.significantPrecipitationThreshold {
                    Text("\(precipitationProbability)%")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
            }
            .frame(height: symbolBlockHeight)

            TemperatureView(temperature: temperature)
                .font(temperatureFont)
                .fontWeight(style == .regular ? nil : .semibold)
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
