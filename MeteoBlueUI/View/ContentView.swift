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
    @Environment(MeteoData.self) private var meteoData

    @State private var displayedTemperature: Int = 0

    init() {
        let appearance = UINavigationBarAppearance()
        let largeTitleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.serif)!
            .withSymbolicTraits(.traitBold)!
        let titleDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.serif)!
        appearance.largeTitleTextAttributes = [
            .font: UIFont(descriptor: largeTitleDescriptor, size: 0)
        ]
        appearance.titleTextAttributes = [
            .font: UIFont(descriptor: titleDescriptor, size: 0)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().layoutMargins.left = 20
        UINavigationBar.appearance().layoutMargins.right = 20
    }

    var body: some View {
        Group {
            if let location = meteoData.location {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 32) {
                            if let firstDay = meteoData.dayByDay.first {
                                CurrentWeatherView(
                                    firstDay: firstDay
                                )
                            }

                            HourByHourView(days: meteoData.dayByDay)

                            DayByDayView(days: meteoData.dayByDay)

                            MapsView()
                        }
                        .padding(.horizontal, 20)
                    }
                    .navigationTitle(location.city)
                    .navigationSubtitle(location.country)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            SettingsView()
                        }
                        ToolbarItem(placement: .topBarLeading) {
                            FavoriteCitiesView()
                        }
                        if let currentLocation = locationManager.currentLocation {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    Task {
                                        await meteoData.loadMeteoData(
                                            location: currentLocation,
                                            isCurrentLocation: true
                                        )
                                    }
                                } label: {
                                    Image(
                                        systemName: locationManager.currentLocation == location ? "location.fill" : "location"
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
                            location: location,
                            isCurrentLocation: locationManager.currentLocation == location
                        )
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color("BackgroundColor"))
                }

            } else if let errorMessage = meteoData.error {
                VStack(spacing: 8) {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)

                    Button("retry") {
                        Task {
                            await meteoData.loadMeteoData()
                        }
                    }

                    SettingsView {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("settings.title")
                        }
                    }
                }
                .padding()
            } else {
                ProgressView()
                    .padding()
            }
        }
        .task {
            await meteoData.loadMeteoData()
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @StateObject var mockData = MockMeteoData()
    @Previewable @StateObject var locationManager = LocationManager()

    ContentView()
        .environmentObject(mockData as MeteoData)
        .environmentObject(locationManager)
        .appBackground()
}
