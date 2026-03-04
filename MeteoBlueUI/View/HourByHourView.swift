//
//  HourByHourView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct HourByHourView: View {
    let days: [MeteoDataDay]

    private var hourByHour: [MeteoData1H] {
        guard days.count >= 2 else { return [] }
        let currentDay = days[0]
        let nextDay = days[1]

        let currentHourByHour = currentDay.hourByHour.filter {
            $0.time
                >= Calendar.current.date(
                    from: Calendar.current.dateComponents(
                        [.year, .month, .day, .hour],
                        from: Date()
                    )
                ) ?? Date()
        }

        return currentHourByHour
            + nextDay.hourByHour.prefix(24 - currentHourByHour.count)
    }

    private func formattedHour(from date: Date) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH' h'"
        return outputFormatter.string(from: date)
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 24) {
                ForEach(hourByHour) { item in
                    VStack(spacing: 10) {
                        Text(
                            item == hourByHour.first
                                ? String(localized: "hour-by-hour.now")
                                : formattedHour(from: item.time)
                        )
                        .font(.body)
                        .foregroundColor(.secondary)

                        SymbolView(
                            symbol: item.symbol,
                            description: item.description
                        )
                        .font(.system(size: 24))
                        .frame(width: 24, height: 24)

                        TemperatureView(temperature: item.temperature)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()

    let defaultCity = LocationManager.defaultMapItem()

    VStack {
        HourByHourView(days: mockData.dayByDay)
        Button("Refresh") {
            Task {
                await mockData.loadMeteoData(force: true, city: defaultCity)
            }
        }
    }
    .padding(.horizontal, 16)
    .appBackground()
    .task {
        await mockData.loadMeteoData(city: defaultCity)
    }
}
