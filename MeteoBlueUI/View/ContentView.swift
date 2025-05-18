//
//  ContentView.swift
//  MeteoBlueUI
//
//  Created by Raphaël Catarino on 07/05/2025.
//

import MapKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject private var meteoData: MeteoData

    @State private var displayedTemperature: Int = 0

    func areMapItemsEqual(_ item1: MKMapItem?, _ item2: MKMapItem?) -> Bool {
        guard let item1 = item1, let item2 = item2 else {
            return false
        }
        return item1.placemark.locality == item2.placemark.locality
            && item1.placemark.country == item2.placemark.country
    }

    var body: some View {
        VStack {
            if let city = meteoData.city,
                let firstDay = meteoData.dayByDay.first,
                let firstHour = firstDay.hourByHour.first
            {
                NavigationStack {
                    ZStack {
                        //                        LinearGradient(
                        //                            colors: [.blue.opacity(0.5), .blue.opacity(0.8)],
                        //                            startPoint: .top,
                        //                            endPoint: .bottom
                        //                        )
                        //                        .ignoresSafeArea()
                        ScrollView {
                            VStack {
                                if let country = city.placemark.country {
                                    HStack(spacing: 4) {
                                        Text(country)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                                VStack(spacing: 16) {
                                    VStack {
                                        HStack {
                                            Image(systemName: firstHour.symbol)
                                                .font(.system(size: 50))
                                                .symbolRenderingMode(
                                                    .multicolor
                                                )
                                                .frame(height: 54)
                                                .id("symbol")
                                                .transition(.opacity)
                                                .animation(
                                                    .easeOut,
                                                    value: firstHour.symbol
                                                )
                                            Text(
                                                "\(Int(round(firstHour.temperature)))°"
                                            )
                                            .font(.system(size: 54))
                                            .id("temperature")
                                            .contentTransition(.numericText())
                                            .animation(
                                                .easeInOut,
                                                value: firstHour.temperature
                                            )
                                        }
                                        .shadow(
                                            color: .secondary.opacity(0.5),
                                            radius: 18
                                        )
                                        Text(firstHour.description)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                            .id("description")
                                            .transition(.opacity)
                                            .animation(
                                                .easeOut,
                                                value: firstHour.description
                                            )
                                    }

                                    HourByHourView(
                                        currentDay: firstDay,
                                        nextDay: meteoData.dayByDay[1]
                                    )

                                    DayByDayView(
                                        dayByDay: meteoData.dayByDay
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .navigationTitle(
                            city.placemark.locality ?? "Unknown"
                        )
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                FavoriteCitiesView()
                            }
                            if let currentCity = locationManager.city {
                                ToolbarItem(
                                    placement: .navigationBarTrailing
                                ) {
                                    Button {
                                        Task {
                                            await meteoData.loadMeteoData(
                                                city: currentCity
                                            )
                                        }
                                    } label: {
                                        Image(
                                            systemName: areMapItemsEqual(
                                                locationManager.city,
                                                city
                                            ) ? "location.fill" : "location"
                                        )
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                SearchCityView()
                            }
                        }
                        .refreshable {
                            await meteoData.loadMeteoData(
                                force: true,
                                city: city
                            )
                        }
                    }
                }
            } else if let errorMessage = meteoData.error {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                ProgressView()
                    .padding()
            }
        }
        .task {
            await meteoData.loadMeteoData(city: locationManager.city!)
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @StateObject var locationManager = LocationManager()

    if locationManager.city != nil {
        ContentView()
            .environmentObject(MockMeteoData() as MeteoData)
            .environmentObject(locationManager)
    } else {
        ProgressView()
    }
}
