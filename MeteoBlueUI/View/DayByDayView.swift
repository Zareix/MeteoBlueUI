//
//  DayByDayView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct DayByDayView: View {
    let dayByDay: [MeteoDataDay]

    @State private var selectedDescription = ""
    @State private var selectedItem: MeteoDataDay?

    private func formatPrecipitation(_ precipitation: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        if let formattedString = formatter.string(
            from: NSNumber(value: precipitation)
        ) {
            return formattedString
        } else {
            return "\(precipitation)"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(
                Array(dayByDay.enumerated()),
                id: \.element.time
            ) {
                index,
                item in

                if index != 0 {
                    Divider()
                }

                HStack(spacing: 16) {
                    Text(
                        index == 0
                            ? String(localized: "day-by-day.today")
                            : item.time.formatted(
                                .dateTime.weekday(.abbreviated)
                            ).capitalized
                    )
                    .font(.body)
                    .frame(width: 40, alignment: .leading)

                    HStack(spacing: 8) {
                        Image(systemName: item.symbol)
                            .symbolRenderingMode(.multicolor)
                            .shadow(color: .secondary.opacity(0.3), radius: 8)
                            .font(.system(size: 20))
                            .frame(width: 20, height: 20)
                        if item.precipitation > 0 {
                            Text(
                                "\(formatPrecipitation(item.precipitation)) mm"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(
                                "\(Int(round(item.temperatureMin)))°"
                            )
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .frame(minWidth: 30)
                        }

                        HStack(spacing: 0) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                            Text(
                                "\(Int(round(item.temperatureMax)))°"
                            )
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(minWidth: 30)
                        }
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItem = item
                }
            }
            .sheet(
                item: $selectedItem,
                onDismiss: {
                    selectedItem = nil
                }
            ) { selectedItem in
                DayDetailsView(dayByDay: dayByDay, selectedItem: selectedItem)
            }
        }
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
        DayByDayView(
            dayByDay: mockData.dayByDay
        )
        .environmentObject(mockData as MeteoData)
        .task {
            await mockData.loadMeteoData(city: city)
        }
    } else {
        ProgressView()
    }
}
