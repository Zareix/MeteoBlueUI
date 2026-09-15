//
//  WatchWeatherWidget.swift
//  MeteoBlueUIWatchWidget
//
//  Created by Raphaël Catarino on 15/09/2026.
//

import OSLog
import SwiftUI
import WidgetKit

private let watchWidgetLogger = Logger(subsystem: "com.raphaelgc.MeteoBlueUI", category: "WatchWeatherWidget")

// MARK: - Timeline Entry

struct WatchWeatherEntry: TimelineEntry {
    let date: Date
    let temperature: Double
    let symbol: String
    let dailyTemperatureMax: Double?
    let dailyTemperatureMin: Double?
    let hours: [WidgetHourEntry]
}

// MARK: - Provider

struct WatchWeatherProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WatchWeatherEntry {
        Self.placeholderEntry()
    }

    /// Un tableau vide indique au système que le widget est configurable
    /// (interface d'édition disponible à partir de watchOS 26).
    func recommendations() -> [AppIntentRecommendation<SelectProviderIntent>] {
        []
    }

    func snapshot(for configuration: SelectProviderIntent, in context: Context) async -> WatchWeatherEntry {
        let providerType = configuration.provider.resolvedType

        // Pas d'appel GPS ici (l'aperçu doit rester rapide) : lecture directe du cache,
        // comme le fait NextHoursProvider sur iOS.
        let data: WidgetData?
        if configuration.locationSource == .favorite, let favorite = configuration.favorite?.weatherLocation {
            data = WidgetDataService.loadFromCache(providerType: providerType, locationID: favorite.id)
        } else {
            data = WidgetDataService.mostRecentCache(providerType: providerType)
        }

        if let data, let current = data.hours.first {
            return Self.makeEntry(date: .now, current: current, data: data)
        }
        return Self.placeholderEntry()
    }

    func timeline(for configuration: SelectProviderIntent, in context: Context) async -> Timeline<WatchWeatherEntry> {
        let providerType = configuration.provider.resolvedType
        let preferredFavorite = configuration.locationSource == .favorite ? configuration.favorite?.weatherLocation : nil
        let location = await WidgetDataService.resolveLocation(preferredFavorite: preferredFavorite)

        // Cache frais (< 1h) : on l'utilise tel quel pour ne pas spammer l'API.
        if !WidgetDataService.isStale(providerType: providerType, locationID: location.id),
           let cached = WidgetDataService.loadFromCache(providerType: providerType, locationID: location.id),
           let current = cached.hours.first
        {
            let entries = Self.makeHourlyEntries(current: current, data: cached)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
            return Timeline(entries: entries, policy: .after(nextUpdate))
        }

        do {
            let widgetData = try await WidgetDataService.fetchWidgetData(for: location, providerType: providerType)
            guard let current = widgetData.hours.first else {
                throw AppError.runtimeError("No forecast data")
            }
            let entries = Self.makeHourlyEntries(current: current, data: widgetData)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
            return Timeline(entries: entries, policy: .after(nextUpdate))
        } catch {
            watchWidgetLogger.error("Watch widget fetch failed [\(providerType.rawValue)]: \(error.localizedDescription)")

            if let cached = WidgetDataService.loadFromCache(providerType: providerType, locationID: location.id),
               let current = cached.hours.first
            {
                let entries = Self.makeHourlyEntries(current: current, data: cached)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
                return Timeline(entries: entries, policy: .after(nextUpdate))
            }

            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now) ?? .now
            return Timeline(entries: [Self.placeholderEntry()], policy: .after(nextUpdate))
        }
    }

    // MARK: Timeline helpers

    private static func makeEntry(date: Date, current: WidgetHourEntry, data: WidgetData) -> WatchWeatherEntry {
        WatchWeatherEntry(
            date: date,
            temperature: current.temperature,
            symbol: current.symbol,
            dailyTemperatureMax: data.dailyTemperatureMax,
            dailyTemperatureMin: data.dailyTemperatureMin,
            hours: data.hours
        )
    }

    /// Une entrée par heure pour que le widget avance même sans reload de la timeline.
    private static func makeHourlyEntries(current: WidgetHourEntry, data: WidgetData) -> [WatchWeatherEntry] {
        let currentHourStart = Calendar.current.dateInterval(of: .hour, for: Date())?.start ?? Date()
        let freshHours = data.hours.filter { $0.time >= currentHourStart }

        guard !freshHours.isEmpty else {
            return [makeEntry(date: .now, current: current, data: data)]
        }

        let maxEntries = Swift.min(freshHours.count, 12)
        return (0..<maxEntries).map { offset in
            let slice = Array(freshHours[offset...])
            let date = offset == 0 ? Date() : slice[0].time
            return makeEntry(date: date, current: slice[0], data: data)
        }
    }

    private static func placeholderEntry() -> WatchWeatherEntry {
        WatchWeatherEntry(
            date: .now,
            temperature: 18,
            symbol: "sun.max.fill",
            dailyTemperatureMax: 21,
            dailyTemperatureMin: 12,
            hours: (0..<6).map { offset in
                WidgetHourEntry(
                    time: Calendar.current.date(byAdding: .hour, value: offset, to: .now) ?? .now,
                    symbol: offset % 2 == 0 ? "sun.max.fill" : "cloud.fill",
                    description: "Sunny",
                    temperature: 18 + Double(offset),
                    precipitationProbability: offset * 5
                )
            }
        )
    }
}

// MARK: - Widget Entry View

/// Widget "météo" du cadran, calqué sur celui d'Apple : une ligne avec le
/// symbole courant, la température et les min/max du jour, puis 5 prochaines heures.
struct WatchWeatherWidgetEntryView: View {
    var entry: WatchWeatherEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .containerBackground(for: .widget) { Color.clear }
    }

    private var content: some View {
        switch family {
        case .accessoryRectangular:
            AnyView(rectangular)
        case .accessoryInline:
            AnyView(Text("\(Image(systemName: entry.symbol)) \(Int(entry.temperature.rounded()))°"))
        case .accessoryCorner:
            AnyView(corner)
        default:
            AnyView(circular)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    SymbolView(symbol: entry.symbol)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("\(Int(entry.temperature.rounded()))°")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }

                if let max = entry.dailyTemperatureMax, let min = entry.dailyTemperatureMin {
                    HStack(spacing: 4) {
                        HStack(spacing: 1) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10))
                            Text("\(Int(max.rounded()))°")
                                .font(.system(size: 12, design: .rounded))
                        }
                        .opacity(0.7)

                        HStack(spacing: 1) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10))
                            Text("\(Int(min.rounded()))°")
                                .font(.system(size: 12, design: .rounded))
                        }
                        .opacity(0.7)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(entry.hours.dropFirst().prefix(5)), id: \.time) { hour in
                    HourCellView(
                        time: hour.time,
                        symbol: hour.symbol,
                        description: hour.description,
                        temperature: hour.temperature,
                        precipitationProbability: hour.precipitationProbability,
                        style: .mini
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var circular: some View {
        VStack(spacing: 1) {
            SymbolView(symbol: entry.symbol)
                .font(.system(size: 22))
            Text("\(Int(entry.temperature.rounded()))°")
                .font(.system(size: 13, design: .rounded))
        }
    }

    private var corner: some View {
        SymbolView(symbol: entry.symbol)
            .font(.system(size: 22))
    }
}

// MARK: - Widget

struct WatchWeatherWidget: Widget {
    let kind: String = "WatchWeatherWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectProviderIntent.self, provider: WatchWeatherProvider()) { entry in
            WatchWeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("Current weather with the day's high and low and the next few hours.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular, .accessoryCorner])
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    WatchWeatherWidget()
} timeline: {
    WatchWeatherEntry(
        date: .now,
        temperature: 18,
        symbol: "sun.max.fill",
        dailyTemperatureMax: 21,
        dailyTemperatureMin: 12,
        hours: (0..<6).map { offset in
            WidgetHourEntry(
                time: Calendar.current.date(byAdding: .hour, value: offset, to: .now) ?? .now,
                symbol: offset % 2 == 0 ? "sun.max.fill" : "cloud.sun.fill",
                description: "Sunny",
                temperature: 18 + Double(offset),
                precipitationProbability: offset * 5
            )
        }
    )
}
