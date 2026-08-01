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

struct NextHoursProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NextHoursEntry {
        NextHoursEntry(
            date: .now,
            cityName: "Paris",
            hours: Self.placeholderHours()
        )
    }

    func snapshot(for configuration: SelectProviderIntent, in context: Context) async -> NextHoursEntry {
        let providerType = configuration.provider.resolvedType
        if let data = WidgetDataService.loadFromCache(providerType: providerType) {
            let currentHourStart = Calendar.current.dateInterval(of: .hour, for: Date())?.start ?? Date()
            let freshHours = data.hours.filter { $0.time >= currentHourStart }
            return NextHoursEntry(date: .now, cityName: data.location.city, hours: freshHours)
        } else {
            return NextHoursEntry(date: .now, cityName: "Loading...", hours: Self.placeholderHours())
        }
    }

    func timeline(for configuration: SelectProviderIntent, in context: Context) async -> Timeline<NextHoursEntry> {
        let providerType = configuration.provider.resolvedType

        // Si le cache est encore frais (< 1h), on l'utilise — évite de spammer l'API
        // quand iOS recharge la timeline plusieurs fois dans la même heure.
        if !WidgetDataService.isStale(providerType: providerType),
           let cached = WidgetDataService.loadFromCache(providerType: providerType)
        {
            let entries = Self.makeEntries(cityName: cached.location.city, hours: cached.hours)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
            return Timeline(entries: entries, policy: .after(nextUpdate))
        }

        // Localisation conservée du cache même s'il est périmé ; sinon favoris > historique > Cupertino.
        let location = WidgetDataService.loadFromCache(providerType: providerType)?.location
            ?? WidgetDataService.fetchCurrentLocation()

        do {
            let widgetData = try await WidgetDataService.fetchWidgetData(for: location, providerType: providerType)
            let entries = Self.makeEntries(cityName: location.city, hours: widgetData.hours)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
            return Timeline(entries: entries, policy: .after(nextUpdate))

        } catch {
            let nsError = error as NSError
            widgetLogger.error(
                "Failed to fetch weather data [\(providerType.rawValue)]: \(error.localizedDescription) — domain=\(nsError.domain) code=\(nsError.code) userInfo=\(nsError.userInfo)"
            )

            if let cached = WidgetDataService.loadFromCache(providerType: providerType) {
                let entries = Self.makeEntries(cityName: cached.location.city, hours: cached.hours)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
                return Timeline(entries: entries, policy: .after(nextUpdate))
            } else {
                let entry = NextHoursEntry(
                    date: .now,
                    cityName: "Error",
                    hours: Self.placeholderHours()
                )
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now) ?? .now
                return Timeline(entries: [entry], policy: .after(nextUpdate))
            }
        }
    }

    // MARK: Timeline helpers

    /// Crée une entrée par heure pour que le widget affiche la bonne heure
    /// même si iOS ne recharge pas la timeline (budget de rafraîchissement limité).
    /// Filtre les heures du passé pour éviter d'afficher un cache périmé.
    private static func makeEntries(cityName: String, hours: [WidgetHourEntry]) -> [NextHoursEntry] {
        let currentHourStart = Calendar.current.dateInterval(of: .hour, for: Date())?.start ?? Date()
        let freshHours = hours.filter { $0.time >= currentHourStart }

        guard !freshHours.isEmpty else {
            return [NextHoursEntry(date: .now, cityName: cityName, hours: [])]
        }

        let maxEntries = min(freshHours.count, 24)
        return (0..<maxEntries).map { offset in
            let slice = Array(freshHours[offset...])
            // La première entrée prend effet immédiatement, les suivantes à l'heure correspondante
            let date = offset == 0 ? Date() : slice[0].time
            return NextHoursEntry(date: date, cityName: cityName, hours: slice)
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
        f.dateFormat = "HH'h'"
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
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Widget Entry View

struct MeteoBlueWidgetEntryView: View {
    var entry: NextHoursEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if family == .systemSmall {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(entry.cityName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .fontDesign(.serif)
                        .lineLimit(1)

                    if let current = entry.hours.first {
                        HStack(alignment: .center) {
                            SymbolView(symbol: current.symbol)
                                .font(.system(size: 42))
                            Text("\(Int(current.temperature.rounded()))°")
                                .font(.system(size: 32))
                                .fontWeight(.medium)
                                .fontDesign(.rounded)
                        }
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                    }

                    Spacer()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(Color("WidgetBackground"), for: .widget)
        } else {
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
                        HStack(spacing: 4) {
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
                    let hoursToDisplay = Array(entry.hours.dropFirst().prefix(6))

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
}

// MARK: - Widget

struct MeteoBlueWidget: Widget {
    let kind: String = "MeteoBlueWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectProviderIntent.self, provider: NextHoursProvider()) { entry in
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

#Preview(as: .systemSmall) {
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
