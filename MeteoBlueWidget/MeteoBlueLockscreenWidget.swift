//
//  MeteoBlueLockscreenWidget.swift
//  MeteoBlueWidget
//
//  Created by Raphaël Catarino on 15/09/2026.
//

import SwiftUI
import WidgetKit

// MARK: - Widget Entry View

struct MeteoBlueLockscreenWidgetEntryView: View {
    var entry: NextHoursEntry

    var body: some View {
        if let current = entry.hours.first {
            Text("\(Image(systemName: current.symbol)) \(Int(current.temperature.rounded()))°")
        } else {
            Text("…")
        }
    }
}

// MARK: - Widget

struct MeteoBlueLockscreenWidget: Widget {
    let kind: String = "MeteoBlueLockscreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectProviderIntent.self, provider: NextHoursProvider()) { entry in
            MeteoBlueLockscreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Current Weather")
        .description("Show the current weather symbol and temperature next to the lock screen date.")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Preview

#Preview(as: .accessoryInline) {
    MeteoBlueLockscreenWidget()
} timeline: {
    NextHoursEntry(
        date: .now,
        cityName: "Paris",
        hours: [
            WidgetHourEntry(
                time: .now,
                symbol: "sun.max.fill",
                description: "Sunny",
                temperature: 18,
                precipitationProbability: 0
            )
        ]
    )
}
