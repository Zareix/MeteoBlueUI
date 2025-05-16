//
//  DayByDayView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct DayByDayView: View {
    let dayByDay: [MeteoDataDay]

    @State private var showAlert = false
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
                            .frame(width: 20)
                        if item.precipitation > 0 {
                            Text(
                                "\(formatPrecipitation(item.precipitation)) mm"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        HStack(spacing: 0) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(
                                "\(Int(round(item.temperatureMin)))°"
                            )
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(width: 30)
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
                            .frame(width: 30)
                        }
                    }
                }
                .onTapGesture {
                    selectedItem = item
                    showAlert = true
                }
            }
            .sheet(
                isPresented: $showAlert
            ) {
                if let selectedItem = selectedItem {
                    ForEach(selectedItem.hourByHour, id: \.time) { item in
                        Text(
                            "\(item.time.formatted(.dateTime.hour())): \(item.description)"
                        )

                    }
                }
            }
            //            .alert("Description", isPresented: $showAlert) {
            //                Button("OK", role: .cancel) {}
            //            } message: {
            //                Text(selectedDescription)
            //            }
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
        .task {
            await mockData.loadMeteoData(city: city)
        }
    } else {
        ProgressView("loading")
    }
}
