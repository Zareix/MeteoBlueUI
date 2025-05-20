//
//  HourByHourView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct HourByHourView: View {
    @EnvironmentObject private var meteoData: MeteoData

    private var hourByHour: [MeteoData1H] {
        let currentDay = meteoData.dayByDay[0]
        let nextDay = meteoData.dayByDay[1]

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

                        Image(systemName: item.symbol)
                            .symbolRenderingMode(.multicolor)
                            .shadow(color: .secondary.opacity(0.3), radius: 8)
                            .font(.system(size: 22))
                            .frame(height: 22)

                        Text(
                            "\(Int(round(item.temperature)).formatted())°"
                        )
                        .font(.body)
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    @Previewable @StateObject var locationManager = LocationManager()

    if let city = locationManager.city {
        VStack {
            if mockData.dayByDay.first != nil {
                HourByHourView()
                    .environmentObject(mockData as MeteoData)
                Button("Refresh") {
                    Task {
                        await mockData.loadMeteoData(force: true, city: city)
                    }
                }
            } else {
                ProgressView()
            }
        }.task {
            await mockData.loadMeteoData(city: city)
        }
    }
}
