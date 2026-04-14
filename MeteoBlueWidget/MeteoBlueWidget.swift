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
        Task {
            widgetLogger.info("📡 Fetching widget data from WidgetDataService")
            let widgetData = await WidgetDataService.loadOrFetch()

            let entry: NextHoursEntry
            if let data = widgetData {
                entry = NextHoursEntry(date: .now, cityName: data.location.city, hours: data.hours)
            } else {
                entry = NextHoursEntry(date: .now, cityName: "—", hours: [])
            }

            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
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
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.cityName)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .fontDesign(.serif)
                .lineLimit(1)

            Divider()

            if entry.hours.isEmpty {
                Text("Loading data…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let displayCount = family == .systemSmall ? 3 : 6
                HStack(spacing: 0) {
                    ForEach(entry.hours.prefix(displayCount), id: \.time) { hour in
                        HourCellView(entry: hour)
                    }
                }
                .padding(.vertical)
                .padding(.top, 2)
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
