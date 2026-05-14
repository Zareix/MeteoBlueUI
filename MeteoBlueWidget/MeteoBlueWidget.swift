//
//  MeteoBlueWidget.swift
//  MeteoBlueWidget
//
//  Created by Raphaël Catarino on 04/03/2026.
//

import AppIntents
import OSLog
import SwiftUI
import WidgetKit

private let widgetLogger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "MeteoBlueWidget")

// MARK: - Timeline Entry

struct NextHoursEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let hours: [WidgetHourEntry]
}

// MARK: - Provider

struct NextHoursProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextHoursEntry {
        NextHoursEntry(
            date: .now,
            cityName: "Paris",
            hours: Self.placeholderHours()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextHoursEntry) -> Void) {
        print("📸 [Widget] getSnapshot called")
        widgetLogger.info("📸 getSnapshot called for NextHoursProvider")
        if let data = WidgetDataService.loadFromCache() {
            completion(NextHoursEntry(date: .now, cityName: data.location.city, hours: data.hours))
        } else {
            completion(NextHoursEntry(date: .now, cityName: "Paris", hours: Self.placeholderHours()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextHoursEntry>) -> Void) {
        widgetLogger.info("⏱️ getTimeline called for NextHoursProvider")
        print("🔵 [Widget] getTimeline START")

        Task {
            // Localisation fixe : Paris
            let parisLocation = WeatherLocation(
                city: "Paris",
                country: "France",
                latitude: 48.8566,
                longitude: 2.3522
            )

            widgetLogger.info("📡 Fetching weather data for Paris")
            print("🔵 [Widget] About to fetch data for Paris...")

            do {
                let widgetData = try await WidgetDataService.fetchWidgetData(for: parisLocation)
                widgetLogger.info("✅ Successfully fetched \(widgetData.hours.count) hours")
                print("🟢 [Widget] SUCCESS! Got \(widgetData.hours.count) hours")

                if widgetData.hours.isEmpty {
                    print("⚠️ [Widget] WARNING: Hours array is EMPTY!")
                }

                // Afficher les 3 premières heures pour debug
                for (index, hour) in widgetData.hours.prefix(3).enumerated() {
                    print("🔵 [Widget] Hour \(index): \(hour.temperature)° - \(hour.description)")
                }

                let entry = NextHoursEntry(
                    date: .now,
                    cityName: parisLocation.city,
                    hours: widgetData.hours
                )

                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
                print("🟢 [Widget] Completing timeline with real data, next update: \(nextUpdate)")
                completion(Timeline(entries: [entry], policy: .after(nextUpdate)))

            } catch {
                widgetLogger.error("❌ Failed to fetch data: \(error.localizedDescription)")
                print("🔴 [Widget] ERROR: \(error)")
                print("🔴 [Widget] Error type: \(type(of: error))")

                // En cas d'erreur, afficher un placeholder
                let entry = NextHoursEntry(
                    date: .now,
                    cityName: "Paris - Error",
                    hours: Self.placeholderHours()
                )

                // Réessayer dans 5 minutes
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now) ?? .now
                print("🔴 [Widget] Completing timeline with PLACEHOLDER, next update: \(nextUpdate)")
                completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            }
        }
    }

    // MARK: Placeholder helpers

    private static func placeholderHours() -> [WidgetHourEntry] {
        (0..<6).map { offset in
            WidgetHourEntry(
                time: Calendar.current.date(byAdding: .hour, value: offset, to: .now) ?? .now,
                symbol: offset % 2 == 0 ? "sun.max.fill" : "cloud.fill",
                description: "Sunny",
                temperature: 18 + Double(offset),
                precipitationProbability: offset * 5
            )
        }
    }
}

// MARK: - Hour Cell View

struct HourCellView: View {
    let entry: WidgetHourEntry

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: entry.time)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(timeString)
                .font(.caption2)
                .foregroundStyle(.secondary)
            SymbolView(symbol: entry.symbol)
                .font(.title3)
                .frame(width: 24, height: 24)
            Text("\(Int(entry.temperature.rounded()))°")
                .font(.caption)
                .fontWeight(.semibold)
//            Text(entry.precipitationProbability > 0 ? "\(entry.precipitationProbability)%" : " ")
//                .font(.caption2)
//                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Widget Entry View

struct MeteoBlueWidgetEntryView: View {
    var entry: NextHoursEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(entry.cityName)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .fontDesign(.serif)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)

                if let current = entry.hours.first {
                    HStack(spacing: 12) {
                        SymbolView(symbol: current.symbol)
                            .font(.system(size: 32))
                            .frame(height: 32)

                        Text("\(Int(current.temperature.rounded()))°")
                            .font(.system(size: 32))
                            .fontDesign(.rounded)
                    }
                }
            }

            Spacer()

            if entry.hours.isEmpty {
                Text("Loading data…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let displayCount = family == .systemSmall ? 3 : 6
                let hoursToDisplay = Array(entry.hours.dropFirst().prefix(displayCount))

                HStack(spacing: 0) {
                    ForEach(hoursToDisplay, id: \.time) { hour in
                        HourCellView(entry: hour)
                    }
                }
            }
        }
        .containerBackground(Color("WidgetBackground"), for: .widget)
    }
}

// MARK: - Widget

struct MeteoBlueWidget: Widget {
    let kind: String = "MeteoBlueWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextHoursProvider()) { entry in
            MeteoBlueWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Hours")
        .description("See the weather for the next few hours.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    MeteoBlueWidget()
} timeline: {
    NextHoursEntry(
        date: .now,
        cityName: "Paris",
        hours: (0..<6).map { offset in
            WidgetHourEntry(
                time: Calendar.current.date(byAdding: .hour, value: offset, to: .now) ?? .now,
                symbol: offset % 2 == 0 ? "sun.max.fill" : "cloud.sun.fill",
                description: "Sunny",
                temperature: 18 + Double(offset),
                precipitationProbability: 0 // offset * 5
            )
        }
    )
}
