//
//  DayDetailsView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 18/05/2025.
//

import Charts
import SwiftUI

struct DayDetailsView: View {
    var day: MeteoDataDay

    var body: some View {
        NavigationStack {
            VStack {
                Text(
                    day.time.formatted(
                        .dateTime
                            .weekday(.wide)
                            .day(.twoDigits)
                            .month(.wide)
                    )
                    .capitalized
                )

                TemperatureChartView(day: day)
                
                Divider()
                
                PrecipitationChartView(day: day)
                    .padding(.top, 8)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .navigationTitle("day-details.title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    @Previewable @StateObject var locationManager = LocationManager()

    @Previewable @State var open: Bool = true

    if let city = locationManager.city {
        ZStack {
            if let firstDay = mockData.dayByDay.first {
                VStack {
                    Button("Preview") {
                        open.toggle()
                    }
                }.sheet(isPresented: $open) {
                    DayDetailsView(
                        day: firstDay
                    )
                }
            }
        }.task {
            await mockData.loadMeteoData(city: city)
        }
    } else {
        ProgressView()
    }
}
