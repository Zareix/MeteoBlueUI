//
//  MeteoBlueLockscreenForecastWidget.swift
//  MeteoBlueWidget
//
//  Created by Raphaël Catarino on 15/09/2026.
//

import SwiftUI
import WidgetKit

// MARK: - Widget Entry View

struct MeteoBlueLockscreenForecastWidgetEntryView: View {
    var entry: NextHoursEntry

    var body: some View {
        HStack(alignment: .center){
            VStack(alignment: .leading, spacing: 2) {
                if let current = entry.hours.first {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: current.symbol)
                            .font(.system(size: 24))
                        
                        Text("\(Int(current.temperature.rounded()))°")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                    }
                }
                
                if let max = entry.dailyTemperatureMax, let min = entry.dailyTemperatureMin {
                    HStack(spacing: 8) {
                        HStack(spacing: 1) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14))
                            Text("\(Int(max.rounded()))°")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.secondary.opacity(0.7))
                        
                        HStack(spacing: 1) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 14))
                            Text("\(Int(min.rounded()))°")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Widget

struct MeteoBlueLockscreenForecastWidget: Widget {
    let kind: String = "MeteoBlueLockscreenForecastWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectProviderIntent.self, provider: NextHoursProvider()) { entry in
            MeteoBlueLockscreenForecastWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hourly Weather")
        .description("Show the current weather with the day's high and low below the lock screen clock.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    MeteoBlueLockscreenForecastWidget()
} timeline: {
    NextHoursEntry(
        date: .now,
        cityName: "Paris",
        hours: (0..<5).map { offset in
            WidgetHourEntry(
                time: Calendar.current.date(byAdding: .hour, value: offset, to: .now) ?? .now,
                symbol: offset % 2 == 0 ? "sun.max.fill" : "cloud.sun.fill",
                description: "Sunny",
                temperature: 18 + Double(offset),
                precipitationProbability: offset * 5
            )
        },
        dailyTemperatureMax: 21,
        dailyTemperatureMin: 12
    )
}
