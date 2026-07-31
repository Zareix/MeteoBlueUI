//
//  HourByHourView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct HourByHourView: View {
    let days: [MeteoDataDay]

    private let symbolBlockHeight: CGFloat = 40

    /// meteoblue's ensemble often reports 20-30% on days with no real rain risk, so only surface it past that noise floor.
    private let significantPrecipitationProbability = 20

    private enum HourItem: Identifiable {
        case hour(MeteoData1H)
        case sunrise(Date)
        case sunset(Date)

        var id: String {
            switch self {
            case .hour(let h): "h-\(h.time.timeIntervalSince1970)"
            case .sunrise(let d): "sr-\(d.timeIntervalSince1970)"
            case .sunset(let d): "ss-\(d.timeIntervalSince1970)"
            }
        }

        var time: Date {
            switch self {
            case .hour(let h): h.time
            case .sunrise(let d), .sunset(let d): d
            }
        }
    }

    private var hourByHour: [MeteoData1H] {
        guard days.count >= 2 else { return [] }
        let currentDay = days[0]
        let nextDay = days[1]
        let calendar = Calendar.current

        let currentHourByHour = currentDay.hourByHour.filter {
            $0.time
                >= calendar.date(
                    from: calendar.dateComponents(
                        [.year, .month, .day, .hour],
                        from: Date()
                    )
                ) ?? Date()
        }

        return currentHourByHour + nextDay.hourByHour.prefix(26 - currentHourByHour.count)
    }

    private var items: [HourItem] {
        let hours = hourByHour
        guard let first = hours.first?.time, let last = hours.last?.time else { return [] }

        let sunEvents: [HourItem] = days.prefix(2).flatMap { day in
            [HourItem.sunrise(day.sunrise), HourItem.sunset(day.sunset)]
        }.filter { $0.time >= first && $0.time <= last }

        return (hours.map(HourItem.hour) + sunEvents).sorted { $0.time < $1.time }
    }

    private func isMidnight(_ date: Date) -> Bool {
        Calendar.current.component(.hour, from: date) == 0
    }

    private func formattedHour(from date: Date) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH' h'"
        return outputFormatter.string(from: date)
    }

    private func formattedTime(from date: Date) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm"
        return outputFormatter.string(from: date)
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 24) {
                ForEach(items) { item in
                    if case .hour(let hourData) = item {
                        if isMidnight(hourData.time) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 1, height: 60)
                        }
                        hourCell(hourData)
                    } else if case .sunrise(let date) = item {
                        sunCell(date: date, symbol: "sunrise.fill", label: "hour-by-hour.sunrise")
                    } else if case .sunset(let date) = item {
                        sunCell(date: date, symbol: "sunset.fill", label: "hour-by-hour.sunset")
                    }
                }
            }
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
    }

    private func hourCell(_ item: MeteoData1H) -> some View {
        VStack(spacing: 10) {
            Text(
                item == hourByHour.first
                    ? String(localized: "hour-by-hour.now")
                    : formattedHour(from: item.time)
            )
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

            VStack(spacing: 4) {
                SymbolView(symbol: item.symbol, description: item.description)
                    .font(.system(size: 24))
                    .frame(width: 24, height: 24)

                if item.precipitationProbability >= significantPrecipitationProbability {
                    Text("\(item.precipitationProbability)%")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
            }
            .frame(height: symbolBlockHeight)

            TemperatureView(temperature: item.temperature)
                .font(.body)
                .foregroundColor(.primary)
        }
    }

    private func sunCell(date: Date, symbol: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 10) {
            Text(formattedTime(from: date))
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Image(systemName: symbol)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 24))
                .frame(width: 24, height: symbolBlockHeight)

            Text(label)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()

    let defaultLocation = LocationManager.defaultLocation()

    VStack {
        HourByHourView(days: mockData.dayByDay)
        Button("Refresh") {
            Task {
                await mockData.loadMeteoData(force: true, location: defaultLocation)
            }
        }
    }
    .padding(.horizontal, 16)
    .appBackground()
    .task {
        await mockData.loadMeteoData(location: defaultLocation)
    }
}
