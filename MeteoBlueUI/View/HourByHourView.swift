//
//  HourByHourView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 13/05/2025.
//
import SwiftUI

struct HourByHourView: View {
    let hourByHour: [MeteoData1H]

    @State private var showAlert = false
    @State private var selectedDescription = ""

    private func formattedHour(from date: Date) -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH' h'"
        return outputFormatter.string(from: date)
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 24) {
                ForEach(
                    Array(hourByHour.enumerated()),
                    id: \.element.time
                ) {
                    index,
                    item in
                    VStack(spacing: 10) {
                        Text(
                            index == 0
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
                    .onTapGesture {
                        selectedDescription = item.description
                        showAlert = true
                    }
                }
            }
        }
        .alert("Description", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(selectedDescription)
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
            if let firstDay = mockData.dayByDay.first {
                HourByHourView(
                    hourByHour: firstDay.hourByHour
                )
            } else {
                ProgressView("loading")
            }
        }.task {
            await mockData.loadMeteoData(city: city)
        }
    }
}
